# Terraform State File Location

terraform {
  backend "s3" {
    bucket = "htakemoto-terraform-state-us-east-1"
    key    = "terraform-serverless-sample/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
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
  apigateway_name = "${local.app_name}-${var.env[terraform.workspace].environment}"
  lambda_name = "${local.app_name}-${var.env[terraform.workspace].environment}"
  lambda_layer_name = "${local.app_name}-${var.env[terraform.workspace].environment}-layer"
  lambda_runtime = "nodejs14.x"
}

# API Gateway

module "api-gateway" {
  source = "./modules/api-gateway"
  # plain variables to override api-gateway/variables.tf
  name = local.apigateway_name
  description = "Terraform serverless application sample"
  stage_name = "v1"
  # referenced variables from lambda/output.tf
  invoke_arn = module.lambda.invoke_arn
}

# Layer Prep

resource "null_resource" "layer_prep" {
  triggers = {
    "always_run" = timestamp()
  }
  provisioner "local-exec" {
    command = <<-EOT
      rm -rf ./layer/nodejs/*
      mkdir -p ./layer/nodejs
      cp ../package.json ../package-lock.json ./layer/nodejs
      npm --prefix ./layer/nodejs i --production
    EOT
  }
}

# Archive

data "archive_file" "lambda_layer_zip" {
  type = "zip"
  source_dir = "./layer"
  output_path = "./lambda/layer.zip"
  depends_on = [
    null_resource.layer_prep
  ]
}

data "archive_file" "lambda_function_zip" {
  type = "zip"
  source_dir = "../src"
  output_path = "./lambda/function.zip"
}

# Lambda Layer

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = local.lambda_layer_name
  filename = data.archive_file.lambda_layer_zip.output_path
  source_code_hash = data.archive_file.lambda_layer_zip.output_base64sha256
  compatible_runtimes = [local.lambda_runtime]
}

# Lambda Function

module "lambda" {
  source = "./modules/lambda"
  # plain variables to override lambda/variables.tf
  function_name = local.lambda_name
  filename = data.archive_file.lambda_function_zip.output_path
  source_code_hash = data.archive_file.lambda_function_zip.output_base64sha256
  layers = [aws_lambda_layer_version.lambda_layer.arn]
  handler = "main.handler"
  memory_size = 256
  runtime = local.lambda_runtime
  timeout = 10
  role = "arn:aws:iam::771192482646:role/serverless-lambda-basic-role"
  variables = {
    ENVIRONMENT = var.env[terraform.workspace].environment
    WORKSPACE = terraform.workspace
  }
  # referenced variables from api-gateway/output.tf
  execution_arn = module.api-gateway.execution_arn
}