resource "aws_lambda_function" "sample" {
  function_name = var.function_name

  s3_bucket = var.s3_bucket
  s3_key    = var.s3_key

  handler = var.handler
  runtime = var.runtime
  role = var.role

  environment {
    variables = var.variables
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sample.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${var.execution_arn}/*/*"
}