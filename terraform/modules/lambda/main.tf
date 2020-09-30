resource "aws_lambda_function" "sample" {
  function_name = var.function_name

  filename = var.filename
  source_code_hash = var.source_code_hash
  layers = var.layers

  handler = var.handler
  memory_size = var.memory_size
  runtime = var.runtime
  timeout = var.timeout
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