{
  "version" : "2017-02-28",
  "operation": "Invoke",
  "payload": {
     "args": $util.toJson($context.args),
     "parent": $util.toJson($context.source),
     "query": $util.toJson($context.info),
     "identity": $util.toJson($context.identity),
     "request": $util.toJson($context.request)
  }
}
