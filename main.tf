variable "aws_profile" {
  default = "YOUR_PROFILE"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = var.aws_profile
}

module "api-gateway" {
  source = "./modules/api-gateway"
  # plain variables to override api-gateway/variables.tf
  name = "terraform-sample"
  description = "Terraform Serverless Application Sample"
  stage_name = "test"
  # referenced variables from lambda/output.tf
  invoke_arn = module.lambda.invoke_arn
}

module "lambda" {
  source = "./modules/lambda"
  # plain variables to override lambda/variables.tf
  function_name = "terraform-sample"
  s3_bucket = "ht-terraform-serverless-sample"
  s3_key = "v1.0.0/sample.zip"
  handler = "main.handler"
  runtime = "nodejs12.x"
  role = "arn:aws:iam::xxxxxxxxx:role/serverless-lambda-basic-role"
  # referenced variables from api-gateway/output.tf
  execution_arn = module.api-gateway.execution_arn
}

output "base_url" {
  value = module.api-gateway.base_url
}