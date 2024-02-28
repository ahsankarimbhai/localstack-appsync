# localstack-appsync

## Setup

1. Run localstack:
    ```
    export LOCALSTACK_AUTH_TOKEN="<YOUR_TOKEN>"
    docker-compose up -d
    ```
2. Make sure you configure your system to use localstack DNS server (See instructions here: https://docs.localstack.cloud/user-guide/tools/dns-server/#system-dns-configuration)
3. Run following commands to deploy to localstack:
    ```
    cd backend
    yarn
    yarn zip
    cd ../terraform
    tflocal init
    tflocal apply -lock=false -auto-approve -var-file=environments/localstack/variables.tfvars
    ```

    If you see the following error, please ignore.
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

  1. Make following GraphQL API call using Postman (or some other client):
      ```
      URL: https://localstack-posaas.localpostureservice.name/api
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
                "listGames": [
                    {
                        "userId": "1",
                        "gameId": "1",
                        "content": "New Game",
                        "attachment": "SampleLogo.png",
                        "createdAt": "01-01-2024",
                        "isActive": false
                    }
                ]
            }
        }
      ```
  4. Check localstack docker logs for error and trace dumps

  ### Expected Result:
  Request should be successful with request successfully getting routed with Route53 -> CloudFront -> API Gateway -> AppSync -> Lambda. We should we following response:
 
    ```
    {
        "__type": "InternalError",
        "message": "exception while calling apigateway with unknown operation: Traceback (most recent call last):\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack/aws/protocol/parser.py\", line 556, in parse\n    operation, uri_params = self._operation_router.match(request)\n                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack/aws/protocol/op_router.py\", line 321, in match\n    rule, args = matcher.match(path, method=method, return_rule=True)\n                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/werkzeug/routing/map.py\", line 624, in match\n    raise NotFound() from None\nwerkzeug.exceptions.NotFound: 404 Not Found: The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.\n\nThe above exception was the direct cause of the following exception:\n\nTraceback (most recent call last):\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/rolo/gateway/chain.py\", line 166, in handle\n    handler(self, self.context, response)\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack/aws/handlers/service.py\", line 62, in __call__\n    return self.parse_and_enrich(context)\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack/aws/handlers/service.py\", line 66, in parse_and_enrich\n    operation, instance = parser.parse(context.request)\n                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack/aws/protocol/parser.py\", line 171, in wrapper\n    return func(*args, **kwargs)\n           ^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack/aws/protocol/parser.py\", line 558, in parse\n    raise OperationNotFoundParserError(\nlocalstack.aws.protocol.parser.OperationNotFoundParserError: Unable to find operation for request to service apigateway: POST /api\n"
    }
    ```

  ### Actual Result:
  Correct GraphQL API response should be returned as follows:

      ```
        {
            "data": {
                "listGames": [
                    {
                        "userId": "1",
                        "gameId": "1",
                        "content": "New Game",
                        "attachment": "SampleLogo.png",
                        "createdAt": "01-01-2024",
                        "isActive": false
                    }
                ]
            }
        }
      ```

  Also note that above response is also returned when we call the API with APi Gateway URL (for e.g. https;//8s6glhz7gw.execute-api.us-east-1.amazonaws.com/default)

  ## Remarks:

  I have verified that localstack works with Route53 -> CloudFront -> S3 integration. You can also test this by following these steps:

  1. Run following commands:
      ```
      cd route-53-test
      tflocal init
      tflocal apply -lock=false -auto-approve
      awslocal s3 cp /tmp/hello.txt s3://mybucket/hello.txt --acl public-read
      ```
  2. Use following CURL command to get S3 object:
      `curl -k https://localstack-posaas.localpostureservice.name/mybucket-ahsanb/hello.txt`