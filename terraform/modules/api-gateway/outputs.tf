output "base_url" {
  value = aws_api_gateway_deployment.agw.invoke_url
}

output "api_key" {
  value = aws_api_gateway_api_key.apikey.value
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.rest.execution_arn
}