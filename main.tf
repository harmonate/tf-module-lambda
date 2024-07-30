resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

resource "aws_s3_bucket" "temp_lambda_code" {
  bucket        = "${var.temp_s3_bucket_prefix}-${var.function_name}-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.temp_lambda_code.id
  key    = "${var.function_name}.zip"
  source = data.archive_file.lambda_zip.output_path
  etag   = filemd5(data.archive_file.lambda_zip.output_path)
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = var.iam_role_name
  assume_role_policy = var.assume_role_policy
}

resource "aws_iam_role_policy" "custom_policies" {
  count  = length(var.iam_policies)
  name   = var.iam_policies[count.index].name
  role   = aws_iam_role.lambda_execution_role.id
  policy = var.iam_policies[count.index].policy
}

resource "aws_iam_role_policy_attachment" "arn_policies" {
  count      = length(var.iam_policy_arns)
  policy_arn = var.iam_policy_arns[count.index]
  role       = aws_iam_role.lambda_execution_role.name
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda-${random_string.suffix.result}.zip"
  source_dir  = var.source_dir
  excludes    = ["package"]
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  handler          = var.handler
  runtime          = var.runtime
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = var.environment_variables
  }

  timeout     = var.timeout
  memory_size = var.memory_size

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${var.source_dir}/package
      pip install -r ${var.requirements_file} -t ${var.source_dir}/package
      cp ${var.source_dir}/${var.handler_filename} ${var.source_dir}/package/
    EOT
  }
}

resource "null_resource" "delete_temp_bucket" {
  triggers = {
    lambda_arn = aws_lambda_function.this.arn
  }

  provisioner "local-exec" {
    command = <<EOF
      aws s3 rm s3://${aws_s3_bucket.temp_lambda_code.id} --recursive
      aws s3api delete-bucket --bucket ${aws_s3_bucket.temp_lambda_code.id}
    EOF
  }

  depends_on = [aws_lambda_function.this]
}
