"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const HandlerCreator_1 = require("./common/lambdahandler/HandlerCreator");
const mappings = require('./graphql-api/handlers');
exports.handler = (0, HandlerCreator_1.createHandler)(mappings);
