# tf-module lambda

```hcl

module "lambda_function" {
  source = "git::https://github.com/harmonate/tf-module-lambda.git?ref=main"

  project_name          = "common_project"
  region                = "us-west-2"
  function_name         = "my-lambda-function"
  handler               = "lambda.handler"
  runtime               = "python3.8"
  source_path           = "lambda/my-lambda-function"
  environment_variables = {
    VAR1 = "value1"
    VAR2 = "value2"
  }
  timeout          = 120
  memory_size      = 256
  policy_json_path = "./policy.json"
}

```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Action": "s3:GetObject",
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::example_bucket/*"
    }
  ]
}
```
