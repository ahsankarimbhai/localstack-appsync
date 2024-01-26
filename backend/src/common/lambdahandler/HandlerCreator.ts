import _ from 'lodash';
import { LambdaHandler } from './LambdaHandler';

export const createHandler = (mapping: any) => async (event: any, context: any) => {
  // Log first!
  console.log('in createHandler');
  console.log("EVENT\n" + JSON.stringify(event, null, 2))

  // Make sure we have a mapping for the field
  const fieldName = _.get(event, 'query.fieldName');
  const handler = mapping[fieldName];
  if (!_.isFunction(handler)) {
    const msg = `No mapping for field '${fieldName}' found`;
    console.log(msg);
  }

  // Forward to processing
  try {
    const pipelines = new LambdaHandler(handler).toPipelines();
    const res = await pipelines(event, context);
    return res;
  } catch (err: any) {
    // Return error in the proper format to be detected by response template
    console.log(err);
  }
};
