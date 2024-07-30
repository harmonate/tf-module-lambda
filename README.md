# Lambda Module

## Python Usage

Assumes lambda code is python and exists in a `lambda_code` folder

```hcl
module "my_lambda_function" {
  source = "git::https://github.com/harmonate/tf-module-lambda.git?ref=main"

  region        = "us-west-2"
  project_name  = var.project_name
  function_name = "test-module-function"

  handler           = "main.handler"
  runtime           = "python3.10"
  source_dir        = "${path.module}/lambda_code"
  requirements_file = "${path.module}/lambda_code/requirements.txt"
  handler_filename  = "main.py"

  environment_variables = {
    ENV_VAR1       = "value1"
    ENV_VAR2       = "value2"
    S3_BUCKET_NAME = module.my_s3_bucket.bucket_name
  }

  timeout     = 30
  memory_size = 256

  iam_role_name = "my-lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  iam_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  iam_policies = [
    {
      name = "s3-access-policy"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:ListBucket"
            ]
            Resource = [
              module.my_s3_bucket.bucket_arn,
              "${module.my_s3_bucket.bucket_arn}/*"
            ]
          }
        ]
      })
    }
  ]
}

output "lambda_function_arn" {
  value = module.my_lambda_function.lambda_function_arn
}

output "lambda_function_name" {
  value = module.my_lambda_function.lambda_function_name
}


module "my_s3_bucket" {
  source = "git::https://github.com/harmonate/tf-module-s3-bucket.git?ref=main" # Assuming the S3 module is in a subdirectory called "s3-bucket"
  providers = {
    aws.default = aws
  }

  bucket_name       = "harmonate-test-bucket"
  enable_versioning = true
  enable_logging    = false

  bucket_policy_principal = {
    AWS = module.my_lambda_function.lambda_function_role
  }
  bucket_policy_effect = "Allow"
  bucket_policy_action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
}
```

## Node Usage

```hcl
module "nodejs_lambda" {
  source                      = "git::https://github.com/harmonate/tf-module-lambda.git?ref=main"
  function_name               = "my-nodejs-function"
  runtime                     = "nodejs14.x"
  handler                     = "index.handler"
   source_dir                 = "${path.module}/lambda_code"
  nodejs_package_manager      = "npm"
  nodejs_package_manager_command = "ci"
}
```

## Container Image Usage

```hcl
module "container_lambda" {
  source                      = "git::https://github.com/harmonate/tf-module-lambda.git?ref=main"
  function_name = "my-container-function"
  package_type = "Image"
  image_uri    = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-lambda-image:latest"
}
```
