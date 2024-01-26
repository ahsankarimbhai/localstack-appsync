import { createHandler } from './common/lambdahandler/HandlerCreator';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const mappings = require('./graphql-api/handlers');

export const handler = createHandler(mappings);
