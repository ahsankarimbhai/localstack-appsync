"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createHandler = void 0;
const lodash_1 = __importDefault(require("lodash"));
const LambdaHandler_1 = require("./LambdaHandler");
const createHandler = (mapping) => async (event, context) => {
    console.log('in createHandler');
    console.log("EVENT\n" + JSON.stringify(event, null, 2));
    const fieldName = lodash_1.default.get(event, 'query.fieldName');
    const handler = mapping[fieldName];
    if (!lodash_1.default.isFunction(handler)) {
        const msg = `No mapping for field '${fieldName}' found`;
        console.log(msg);
    }
    try {
        const pipelines = new LambdaHandler_1.LambdaHandler(handler).toPipelines();
        const res = await pipelines(event, context);
        return res;
    }
    catch (err) {
        console.log(err);
    }
};
exports.createHandler = createHandler;
