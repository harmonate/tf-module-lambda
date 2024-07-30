variable "region" {
  description = "The AWS region to deploy the Lambda function"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "The handler for the Lambda function"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "The runtime for the Lambda function"
  type        = string
  default     = "python3.8"
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Timeout for the Lambda function"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Memory size for the Lambda function"
  type        = number
  default     = 128
}

variable "iam_role_name" {
  description = "Name of the IAM role to create"
  type        = string
  default     = "my_lambda_role"
}

variable "assume_role_policy" {
  description = "JSON formatted string representing the assume role policy"
  type        = string
}

variable "iam_policy_arns" {
  description = "List of IAM policy ARNs to attach to the instance role"
  type        = list(string)
  default     = []
}

variable "iam_policies" {
  description = "List of JSON formatted strings representing IAM policies"
  type = list(object({
    name   = string
    policy = string
  }))
  default = []
}

variable "source_dir" {
  description = "The directory containing the Lambda function source code"
  type        = string
}

variable "requirements_file" {
  description = "The path to the requirements.txt file"
  type        = string
}

variable "handler_filename" {
  description = "The filename of the Lambda handler"
  type        = string
}

variable "temp_s3_bucket_prefix" {
  description = "Prefix for the temporary S3 bucket name"
  type        = string
  default     = "temp-lambda-code"
}