resource "aws_api_gateway_rest_api" "rest" {
  name = var.name
  description = var.description
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invoke_arn
}

# Unfortunately the proxy resource cannot match an empty path at the root of the API.
# To handle that, a similar configuration must be applied to the root resource
# that is built in to the REST API object:

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_rest_api.rest.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.invoke_arn
}

resource "aws_api_gateway_deployment" "agw" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.rest.id
  stage_name  = var.stage_name
}

# API Key Config

resource "aws_api_gateway_api_key" "apikey" {
  name = var.name
}

resource "aws_api_gateway_usage_plan" "usageplan" {
  name         = var.name
  description  = "Usage plan for terraform-sample"

  api_stages {
    api_id = aws_api_gateway_rest_api.rest.id
    stage  = aws_api_gateway_deployment.agw.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.apikey.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usageplan.id
}