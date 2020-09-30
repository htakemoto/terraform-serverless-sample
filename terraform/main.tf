# Install Terraform AWS Plugin

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  version = "~> 3.0"
}

# Variables

variable "env" {
  default = {
    default = {
      environment = "dev"
    }
    dev = {
      environment = "dev"
    }
    prod = {
      environment = "prod"
    }
  }
}

locals {
  app_name = "terraform-serverless-sample"
}

# Terraform State File Location

terraform {
  backend "s3" {
    bucket = "htakemoto-terraform-state-us-east-1"
    key    = "terraform-serverless-sample/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

# API Gateway

module "api-gateway" {
  source = "./modules/api-gateway"
  # plain variables to override api-gateway/variables.tf
  name = "${local.app_name}-${var.env[terraform.workspace].environment}"
  description = "Terraform serverless application sample from ${terraform.workspace}"
  stage_name = "v1"
  # referenced variables from lambda/output.tf
  invoke_arn = module.lambda.invoke_arn
}

# Archive

data "archive_file" "lambda_layer_zip" {
  type = "zip"
  source_dir = "../layer"
  output_path = "../lambda/layer.zip"
}

data "archive_file" "lambda_function_zip" {
  type = "zip"
  source_dir = "../src"
  output_path = "../lambda/function.zip"
}

# Lambda Layer

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "${local.app_name}-${var.env[terraform.workspace].environment}-layer"
  filename = data.archive_file.lambda_layer_zip.output_path
  source_code_hash = data.archive_file.lambda_layer_zip.output_base64sha256
  compatible_runtimes = ["nodejs12.x"]
}

# Lambda Function

module "lambda" {
  source = "./modules/lambda"
  # plain variables to override lambda/variables.tf
  function_name = "${local.app_name}-${var.env[terraform.workspace].environment}"
  filename = data.archive_file.lambda_function_zip.output_path
  source_code_hash = data.archive_file.lambda_function_zip.output_base64sha256
  layers = [aws_lambda_layer_version.lambda_layer.arn]
  handler = "main.handler"
  memory_size = 256
  runtime = "nodejs12.x"
  timeout = 10
  role = "arn:aws:iam::771192482646:role/serverless-lambda-basic-role"
  variables = {
    ENVIRONMENT = var.env[terraform.workspace].environment
    WORKSPACE = terraform.workspace
  }
  # referenced variables from api-gateway/output.tf
  execution_arn = module.api-gateway.execution_arn
}

output "base_url" {
  value = module.api-gateway.base_url
}
output "api_key" {
  value = module.api-gateway.api_key
}