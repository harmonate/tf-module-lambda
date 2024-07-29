resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
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

  depends_on = [null_resource.install_dependencies]
}

resource "null_resource" "install_dependencies" {
  triggers = {
    dependencies_versions = filemd5(var.requirements_file)
    source_versions       = filemd5("${var.source_dir}/${var.handler_filename}")
  }

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${var.source_dir}/package
      pip install -r ${var.requirements_file} -t ${var.source_dir}/package
      cp ${var.source_dir}/${var.handler_filename} ${var.source_dir}/package/
    EOT
  }
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
}
