export const handler = async (event: any) => basicHandler(event);

const basicHandler = async (event: any) => {
  console.log(`Authorizer Event is, err: ${JSON.stringify(event)}`);


  const principalId = "ahbhai@cisco.com";
  const policyDocument = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "execute-api:Invoke",
            "Effect": "Allow",
            "Resource": "arn:aws:execute-api:us-east-1:000000000000:jy25pnfeis/default/POST/api"
        }
    ]
  }
  const context = {
    "tenantUid": "a5ab9844-487d-4077-bf21-690af8c6a7e1",
    "tenantExtId": "1a656045-75bb-4ac5-a52c-1a3fc5a0840c",
    "tenantName": "QkUgRTJFIHRlc3RzIE9yZw==",
    "role": "admin",
    "id": "356b0262-532a-4291-866d-31e30b752da1",
    "irohToken": "sample_token"
  }
  const authObject = { principalId, policyDocument, context };
  console.log(`Authorizer object: ${JSON.stringify(authObject)}`);
  return authObject;
};
