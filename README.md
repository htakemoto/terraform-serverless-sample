# Terraform Serverless Sample

Terraform provides infrastracture as code.<br>
This project is a sample projecct of AWS serverless stack using **API Gateway** and **Lambda**.

## Preparations

1. Install Terraform

    ```bash
    brew install terraform
    ```

2. Install AWS CLI

3. Set up AWS Credentials

    ```bash
    aws configure --profile YOUR_PROFILE
    ```

    Note: you can eliminate profile option if you do not plan to use multipile IAM users on your local

4. Create S3 bucket

    ```bash
    aws s3api create-bucket --bucket=terraform-serverless-sample --region=us-east-1 --profile YOUR_PROFILE
    ```

5. Change AWS profile config at `main.tf`

    ```bash
    ...
    variable "aws_profile" {
        default = "YOUR_PROFILE"
    }
    ...
    ```

6. Create a role for lambda on AWS IAM console and replace the config at `main.tf`

    ```bash
    role = "arn:aws:iam::xxxxxxxxx:role/serverless-lambda-basic-role"
    ```

## Deployment

1. Upload Lambda code as a zip file to S3

    ```bash
    cd src && zip ../sample.zip main.js && ../
    aws s3 cp sample.zip s3://ht-terraform-serverless-sample/v1.0.0/sample.zip --profile YOUR_PROFILE
    ```

2. Set up Terraform plugins

    ```bash
    terraform init
    ```

4. Create Workspace

    ```bash
    # for dev
    terraform workspace new dev
    # for prod
    terraform workspace new prd
    ```

4. Deploy to AWS

    ```bash
    terraform apply
    # or override aws_profile
    terraform apply -var 'aws_profile=YOUR_PROFILE'
    ```

5. Discard Deployment components (optional)

    ```bash
    terraform destroy
    # or override aws_profile
    terraform apply -var 'aws_profile=YOUR_PROFILE'
    ```

    Note: this does not delete S3 bucket


## Terraform Helper Commands

```bash
# format Terraform config files
terraform fmt
# validate Terraform config files
terraform validate
# inspect the current state
terraform show
```