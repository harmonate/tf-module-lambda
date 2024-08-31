output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_invoke_arn" {
  description = "The ARN to invoke the Lambda function"
  value       = aws_lambda_function.this.invoke_arn
}

output "lambda_function_role_arn" {
  description = "The ARN of the IAM role assigned to the Lambda function"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_function_role_name" {
  description = "The name of the CloudWatch Log Group for the Lambda function"
  value       = aws_iam_role.lambda_execution_role.name
}
