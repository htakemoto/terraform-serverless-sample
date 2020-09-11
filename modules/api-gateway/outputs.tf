output "base_url" {
  value = aws_api_gateway_deployment.sample.invoke_url
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.sample.execution_arn
}