# localstack-appsync

## Setup

1. Run localstack:
    ```
    export LOCALSTACK_AUTH_TOKEN="<YOUR_TOKEN>"
    docker-compose up -d
    ```
2. Run following commands to deploy to localstack:
    ```
    cd backend
    yarn
    yarn zip
    cd ../terraform
    terraform init
    terraform apply -lock=false -auto-approve -var-file=environments/localstack/variables.tfvars
    ```

    If you see the following error, just keep re-running the apply command until you see a successful run.
      ```
      ╷
      │ Error: putting API Gateway Integration Response: NotFoundException: No integration defined for method
      │ 
      │   with module.api_gateway.module.cors.aws_api_gateway_integration_response.lambda_gateway_options,
      │   on modules/cors/cors.tf line 36, in resource "aws_api_gateway_integration_response" "lambda_gateway_options":
      │   36: resource "aws_api_gateway_integration_response" "lambda_gateway_options" {
      │ 
      ╵
      ```

  ## Testing

  1. Go API Gateway console and get the API Resource ID for `localstack-posaas` API (For e.g.: lr3gzqgo9w)
  2. Make following GraphQL API call using Postman (or some other client):
      ```
      URL: http://localhost:4566/restapis/lr3gzqgo9w/default/_user_request_
      Headers: {
        Authorization: sample,
        Content-Type: application/json
      }
      Body: {
        "query": "{ listGames { userId gameId content attachment createdAt }}"
      }
      ```
  3. You will see following response returned:
      ```
      {
          "data": {
              "listGames": null
          },
          "errors": [
              {
                  "message": "Expected Iterable, but did not find one for field 'Query.listGames'.",
                  "locations": [
                      {
                          "line": 1,
                          "column": 3
                      }
                  ],
                  "path": [
                      "listGames"
                  ],
                  "errorType": "GraphQLError"
              }
          ]
      }
      ```
  4. Go to CloudWatch Logs console and check the logs for Log Group `/aws/lambda/localstack-posaas-graphql-api`. You should see following event object printed:
  ```
  2024-01-29T23:55:22.570Z 2e9628d8-53c2-49fe-a9ab-1e384daf33c1 INFO EVENT { "args": {}, "parent": null, "query": { "fieldName": "listGames", "parentTypeName": "Query", "variables": {}, "selectionSetList": [] }, "identity": "", "request": {} }
    ```

  ### Expected Result:
  The request object should NOT be empty in the event object received by Lambda function from AppSync. It should look something like this:
  ```
    {
        "args": {}, 
        "parent": null, 
        "query": { 
            "fieldName": "listGames",
            "parentTypeName": "Query", 
            "variables": {}, 
            "selectionSetList": [] 
        },
        "identity": {
            "accountId": "...",
            "cognitoIdentityAuthProvider": null,
            "cognitoIdentityAuthType": null,
            "cognitoIdentityId": null,
            "cognitoIdentityPoolId": null,
            ...
        },
        "request": {
            "headers": {
                ...
                "tenantUid":"b66a29ae-8a6b-4cfd-b753-074413ac7bb2",
                "tenantExtId":"9ce278b8-741e-4e43-be13-1bab5c16fc8f",
                "tenantName":"QVGVzdGluZyBUZW5hbnQ=",
                "role":"admin",
                "id":"fe5e4ba6-95ee-4d40-aa80-24921231888c",
                "irohToken":"sample_token"
            },
            "domainName": null
        }
    }
  ```

  ### Actual Result:
  The request object IS empty in the event object received by Lambda function from AppSync. It looks like this:
  ```
    {
        "args": {},
        "parent": null,
        "query": {
            "fieldName": "listGames",
            "parentTypeName": "Query",
            "variables": {},
            "selectionSetList": []
        },
        "identity": "",
        "request": {}
    }
  ```
