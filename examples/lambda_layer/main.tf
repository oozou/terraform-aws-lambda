locals {
  name = format("%s-%s-%s", var.prefix, var.environment, var.name)
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = "./src/requests.zip"
  layer_name = format("%s-requests-layer", local.name)

  compatible_runtimes = ["python3.8"]
}

module "lambda" {
  source = "../../"

  prefix      = var.prefix
  environment = var.environment
  name        = var.name

  # Source code
  source_code_dir           = "./src"
  file_globs                = ["main.py"]
  compressed_local_file_dir = "./outputs"

  # Lambda Env
  runtime = "python3.8"
  handler = "main.lambda_handler"

  # Lambda Specification
  timeout                            = 3
  memory_size                        = 128
  reserved_concurrent_executions     = -1
  layer_arns                         = [aws_lambda_layer_version.lambda_layer.arn]
  additional_lambda_role_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]

  # Resource policy
  lambda_permission_configurations = {
    # lambda_on_my_account = {
    #   principal  = "apigateway.amazonaws.com"
    #   source_arn = "arn:aws:execute-api:ap-southeast-1:557291035112:lk36vflbha/*/*/"
    # }
  }

  tags = var.custom_tags
}
