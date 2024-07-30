resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

resource "aws_s3_bucket" "lambda_bucket" {
  count         = local.is_image ? 0 : 1
  bucket        = "lambda-${var.function_name}-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_object" "lambda_code" {
  count  = local.is_image ? 0 : 1
  bucket = aws_s3_bucket.lambda_bucket[0].id
  key    = local.filename
  source = local.filename
  etag   = md5(timestamp())

  depends_on = [null_resource.install_dependencies_and_zip]
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

resource "null_resource" "delete_temp_bucket" {
  triggers = {
    lambda_arn = aws_lambda_function.this.arn
  }

  provisioner "local-exec" {
    command = <<EOF
      aws s3 rm s3://${aws_s3_bucket.lambda_bucket[0].id} --recursive
      aws s3api delete-bucket --bucket ${aws_s3_bucket.lambda_bucket[0].id}
    EOF
  }

  depends_on = [aws_lambda_function.this]
}

locals {
  is_python = substr(var.runtime, 0, 6) == "python"
  is_nodejs = substr(var.runtime, 0, 6) == "nodejs"
  is_image  = var.package_type == "Image"
  filename  = "${var.function_name}.zip"
}

resource "null_resource" "install_dependencies_and_zip" {
  count = local.is_image ? 0 : 1
  triggers = {
    dependencies_versions = local.is_python ? (
      var.requirements_file != null ? filemd5(var.requirements_file) : ""
      ) : local.is_nodejs ? (
      filemd5("${var.source_dir}/package.json")
    ) : ""
    source_versions = local.is_python || local.is_nodejs ? filemd5("${var.source_dir}/${var.handler_filename}") : ""
  }

  provisioner "local-exec" {
    command = local.is_python ? (
      var.requirements_file != null ? (
        <<EOT
          mkdir -p ${var.source_dir}/package
          pip install -r ${var.requirements_file} -t ${var.source_dir}/package
          cp ${var.source_dir}/${var.handler_filename} ${var.source_dir}/package/
          cd ${var.source_dir}/package
          zip -r ../../${local.filename} .
        EOT
      ) : "echo 'No requirements file specified for Python runtime'"
      ) : local.is_nodejs ? (
      <<EOT
        cd ${var.source_dir}
        ${var.nodejs_package_manager} ${var.nodejs_package_manager_command}
        zip -r ../${local.filename} .
      EOT
    ) : "echo 'Skipping dependency installation for Image-based Lambda'"
  }
}

resource "local_file" "lambda_zip" {
  count    = local.is_image ? 0 : 1
  filename = local.filename
  content  = "placeholder"

  depends_on = [null_resource.install_dependencies_and_zip]
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_execution_role.arn

  dynamic "image_config" {
    for_each = local.is_image ? [1] : []
    content {
      command           = var.image_config_command
      entry_point       = var.image_config_entry_point
      working_directory = var.image_config_working_directory
    }
  }

  dynamic "environment" {
    for_each = var.environment_variables != null ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  package_type = var.package_type
  image_uri    = local.is_image ? var.image_uri : null
  s3_bucket    = local.is_image ? null : aws_s3_bucket.lambda_bucket[0].id
  s3_key       = local.is_image ? null : aws_s3_object.lambda_code[0].key
  handler      = local.is_image ? null : var.handler
  runtime      = local.is_image ? null : var.runtime

  timeout     = var.timeout
  memory_size = var.memory_size

  source_code_hash = local.is_image ? null : filebase64sha256(local.filename)

  depends_on = [aws_s3_object.lambda_code]
}

