export type HandlerFunc = (event: any, context: any) => Promise<any>;
export type Middleware = (next: HandlerFunc) => HandlerFunc;

export class LambdaHandler {
  readonly domainHandler: HandlerFunc;
  readonly middlewares: Middleware[];

  constructor(domainHandler: HandlerFunc) {
    this.domainHandler = domainHandler;
    this.middlewares = [];
  }

  withMiddlewares(...mws: Middleware[]): LambdaHandler {
    this.middlewares.push(...mws);
    return this;
  }

  /**
   * Return a chained domain handler with all middlewares in the sequence as being registered
   */
  toPipelines = () => async (event: any, context: any) => {
    let handler = this.domainHandler;
    for (let i = this.middlewares.length - 1; i >= 0; i -= 1) {
      handler = await this.middlewares[i](handler);
    }
    const res = await handler(event, context);
    return res;
  };
}
