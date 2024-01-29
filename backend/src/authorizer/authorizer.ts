export const handler = async (event: any) => basicHandler(event);

const basicHandler = async (event: any) => {
  console.log(`Authorizer Event is, err: ${JSON.stringify(event)}`);


  const principalId = "abc@abc.com";
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
    "tenantUid": "b66a29ae-8a6b-4cfd-b753-074413ac7bb2",
    "tenantExtId": "9ce278b8-741e-4e43-be13-1bab5c16fc8f",
    "tenantName": "QVGVzdGluZyBUZW5hbnQ=",
    "role": "admin",
    "id": "fe5e4ba6-95ee-4d40-aa80-24921231888c",
    "irohToken": "sample_token"
  }
  const authObject = { principalId, policyDocument, context };
  console.log(`Authorizer object: ${JSON.stringify(authObject)}`);
  return authObject;
};
