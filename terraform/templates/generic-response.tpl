#if( $context.result && $context.result.errorCode )
    $util.error($context.result.errorSummary, $context.result.errorCode, $context.result.errorId, $context.result.errorCauses)
#else
    $util.toJson($context.result)
#end