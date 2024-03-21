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
      URL: https://localstack-posaas.mypostureservice.name/api
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
            "__type": "InternalError",
            "message": "exception while calling apigateway with unknown operation: Traceback (most recent call last):\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/rolo/gateway/chain.py\", line 166, in handle\n    handler(self, self.context, response)\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/rolo/gateway/handlers.py\", line 27, in __call__\n    router_response = self.router.dispatch(context.request)\n                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/rolo/router.py\", line 378, in dispatch\n    return self.dispatcher(request, handler, args)\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/rolo/dispatcher.py\", line 71, in _dispatch\n    result = endpoint(request, **args)\n             ^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack_ext/services/cloudfront/provider.py.enc\", line 113, in E\n    def E(request,domain=_A,**A):return forward_distribution_invocation(request=request,distribution_id=C)\n                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack_ext/services/cloudfront/provider.py.enc\", line 89, in forward_distribution_invocation\n    B=request;A=invoke_distribution(distribution_id=distribution_id,request=B);C=Response(response=A.content,status=A.status_code,headers=Headers(dict(A.headers)))\n                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack_ext/services/cloudfront/provider.py.enc\", line 312, in invoke_distribution\n    E=select_attributes(dict(E),[HEADER_LOCALSTACK_EDGE_URL]);E=CaseInsensitiveDict(E);E['Host']=B;LOG.info(W,H,A,B);C=requests.request(H,A,data=O,headers=E,verify=_F,allow_redirects=_F,timeout=(5,30));LOG.debug(X,C.status_code,A)\n                                                                                                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/requests/api.py\", line 59, in request\n    return session.request(method=method, url=url, **kwargs)\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/requests/sessions.py\", line 575, in request\n    prep = self.prepare_request(req)\n           ^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/requests/sessions.py\", line 486, in prepare_request\n    p.prepare(\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/requests/models.py\", line 368, in prepare\n    self.prepare_url(url, params)\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/requests/models.py\", line 445, in prepare_url\n    raise InvalidURL(f\"Invalid URL {url!r}: No host supplied\")\nrequests.exceptions.InvalidURL: Invalid URL 'https:///default/api': No host supplied\n"
        }
      ```
  4. Check localstack docker logs for error and trace dumps

  ### Expected Result:
    Request should be successful with request successfully getting routed with Route53 -> CloudFront -> API Gateway -> AppSync -> Lambda. Correct GraphQL API response should be returned as follows:
    
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



  ### Actual Result:

        {
            "__type": "InternalError",
            "message": "exception while calling apigateway with unknown operation: Traceback (most recent call last):\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/rolo/gateway/chain.py\", line 166, in handle\n    handler(self, self.context, response)\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/rolo/gateway/handlers.py\", line 27, in __call__\n    router_response = self.router.dispatch(context.request)\n                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/rolo/router.py\", line 378, in dispatch\n    return self.dispatcher(request, handler, args)\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/rolo/dispatcher.py\", line 71, in _dispatch\n    result = endpoint(request, **args)\n             ^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack_ext/services/cloudfront/provider.py.enc\", line 113, in E\n    def E(request,domain=_A,**A):return forward_distribution_invocation(request=request,distribution_id=C)\n                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack_ext/services/cloudfront/provider.py.enc\", line 89, in forward_distribution_invocation\n    B=request;A=invoke_distribution(distribution_id=distribution_id,request=B);C=Response(response=A.content,status=A.status_code,headers=Headers(dict(A.headers)))\n                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/localstack_ext/services/cloudfront/provider.py.enc\", line 312, in invoke_distribution\n    E=select_attributes(dict(E),[HEADER_LOCALSTACK_EDGE_URL]);E=CaseInsensitiveDict(E);E['Host']=B;LOG.info(W,H,A,B);C=requests.request(H,A,data=O,headers=E,verify=_F,allow_redirects=_F,timeout=(5,30));LOG.debug(X,C.status_code,A)\n                                                                                                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/requests/api.py\", line 59, in request\n    return session.request(method=method, url=url, **kwargs)\n           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/requests/sessions.py\", line 575, in request\n    prep = self.prepare_request(req)\n           ^^^^^^^^^^^^^^^^^^^^^^^^^\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/requests/sessions.py\", line 486, in prepare_request\n    p.prepare(\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/requests/models.py\", line 368, in prepare\n    self.prepare_url(url, params)\n  File \"/opt/code/localstack/.venv/lib/python3.11/site-packages/requests/models.py\", line 445, in prepare_url\n    raise InvalidURL(f\"Invalid URL {url!r}: No host supplied\")\nrequests.exceptions.InvalidURL: Invalid URL 'https:///default/api': No host supplied\n"
        }



  Also note that above response is also returned when we call the API with CloudFront URL directly (for e.g. `https://cbc39fc5.cloudfront.localhost.localstack.cloud/api`)

  So it looks like there is some issue with CloudFront not correctly passing the URL to call API gateway. The error says: 
  `requests.exceptions.InvalidURL: Invalid URL \'https:///default/api\': No host supplied"}`

  The URL should have been `https://8w2qtglsa9.execute-api.us-east-1.amazonaws.com/default/api`. For some reason CloudFront is not adding `Domain Name` specified in the distribution config.

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
      `curl -k https://localstack-posaas.mypostureservice.name/mybucket-ahsanb/hello.txt`