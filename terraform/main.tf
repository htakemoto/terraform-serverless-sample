terraform {
  backend "s3" {
    bucket = "htakemoto-terraform-state-us-east-1"
    key    = "terraform-serverless-sample/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

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

module "api-gateway" {
  source = "./modules/api-gateway"
  # plain variables to override api-gateway/variables.tf
  name = "terraform-serverless-sample-${var.env[terraform.workspace].environment}"
  description = "Terraform serverless application sample from ${terraform.workspace}"
  stage_name = "v1"
  # referenced variables from lambda/output.tf
  invoke_arn = module.lambda.invoke_arn
}

module "lambda" {
  source = "./modules/lambda"
  # plain variables to override lambda/variables.tf
  function_name = "terraform-serverless-sample-${var.env[terraform.workspace].environment}"
  s3_bucket = "htakemoto-terraform-lambda-us-east-1"
  s3_key = "terraform-serverless-sample-${var.env[terraform.workspace].environment}/lambda.zip"
  handler = "src/main.handler"
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