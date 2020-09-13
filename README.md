# Terraform Serverless Sample

Terraform provides infrastracture as code.<br>
This project is a sample projecct of AWS serverless stack using **API Gateway** and **Lambda** with API Key protection.

## Preparations

1. Install Terraform

    ```bash
    brew install terraform
    ```

2. Install AWS CLI

3. Set up AWS Credentials

    ```bash
    aws configure --profile YOUR_PROFILE
    # do export only if you create profile to eliminate profile option for the rest of AWS interactions
    export AWS_PROFILE=YOUR_PROFILE
    ```

    Note: you can eliminate profile option if you do not plan to use multipile IAM users on your local

4. Create S3 bucket

    ```bash
    # create bucket for terraform state
    aws s3api create-bucket --bucket=htakemoto-terraform-state-us-east-1 --region=us-east-1
    # create bucket for lambda package
    aws s3api create-bucket --bucket=htakemoto-terraform-lambda-us-east-1 --region=us-east-1
    # set to block all public access
    aws s3api put-public-access-block \
    --bucket htakemoto-terraform-state-us-east-1 \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    aws s3api put-public-access-block \
    --bucket htakemoto-terraform-lambda-us-east-1 \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    # enable SSE (server side encryption)
    aws s3api put-bucket-encryption \
    --bucket htakemoto-terraform-state-us-east-1 \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
    aws s3api put-bucket-encryption \
    --bucket htakemoto-terraform-lambda-us-east-1 \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
    ```

5. Create a role for lambda on AWS IAM console and replace the config at `main.tf`

    ```bash
    role = "arn:aws:iam::xxxxxxxxx:role/serverless-lambda-basic-role"
    ```

## Deployment

1. If you use profile on AWS CLI, make sure to set an appropriate profile

    ```bash
    export AWS_PROFILE=YOUR_PROFILE
    ```

2. Prepare package files

    ```bash
    # reinstall dependencies but exclude dev dependencies
    npm install --production
    # create a zip
    zip -r lambda.zip src node_modules
    ```

3. Upload Lambda code as a zip file to S3

    ```bash
    # for dev
    aws s3 cp lambda.zip s3://htakemoto-terraform-lambda-us-east-1/terraform-serverless-sample-dev/lambda.zip --sse AES256
    # for prod
    aws s3 cp lambda.zip s3://htakemoto-terraform-lambda-us-east-1/terraform-serverless-sample-prod/lambda.zip --sse AES256
    ```

4. Set up Terraform plugins

    ```bash
    cd terraform
    terraform init
    ```

5. Set Workspace

    For the first time

    ```bash
    # for dev
    terraform workspace new dev
    # for prod
    terraform workspace new prod
    ```

    Next time

    ```bash
    # for dev
    terraform workspace select dev
    # for prod
    terraform workspace select prod
    ```

6. Deploy to AWS

    ```bash
    terraform apply
    ```

    Note: Once complete, you will see the following Outputs

    ```bash
    api_key = xxxxx
    base_url = https://xxxxxx.execute-api.us-east-1.amazonaws.com/v1
    ```

7. Test the URL using GET method with x-api-key header

    ```bash
    curl -H 'x-api-key:xxxxx' https://xxxxxx.execute-api.us-east-1.amazonaws.com/v1
    ```

## Discard Deployment Components

```bash
terraform destroy
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