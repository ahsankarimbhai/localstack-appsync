"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LambdaHandler = void 0;
class LambdaHandler {
    constructor(domainHandler) {
        this.toPipelines = () => async (event, context) => {
            let handler = this.domainHandler;
            for (let i = this.middlewares.length - 1; i >= 0; i -= 1) {
                handler = await this.middlewares[i](handler);
            }
            const res = await handler(event, context);
            return res;
        };
        this.domainHandler = domainHandler;
        this.middlewares = [];
    }
    withMiddlewares(...mws) {
        this.middlewares.push(...mws);
        return this;
    }
}
exports.LambdaHandler = LambdaHandler;
