module "lambda" {
  source = "../../"

  prefix      = var.generic_info.prefix
  environment = var.generic_info.environment
  name        = var.generic_info.name

  is_edge = var.is_edge

  is_create_lambda_bucket = var.is_create_lambda_bucket
  bucket_name             = ""

  source_code_dir           = "./src"
  file_globs                = ["main.py"]
  compressed_local_file_dir = "./outputs"

  runtime = "nodejs12.x"
  handler = "index.handler"

  timeout                        = var.timeout
  memory_size                    = var.memory_size
  reserved_concurrent_executions = -1
  vpc_config                     = var.vpc_config
  dead_letter_target_arn         = var.dead_letter_target_arn

  is_create_lambda_role              = var.is_create_lambda_role
  lambda_role_arn                    = ""
  additional_lambda_role_policy_arns = var.additional_lambda_role_policy_arns

  lambda_permission_configurations = var.lambda_permission_configurations

  is_create_cloudwatch_log_group   = var.is_create_cloudwatch_log_group
  cloudwatch_log_retention_in_days = var.cloudwatch_log_retention_in_days

  ssm_params       = var.ssm_params
  plaintext_params = var.plaintext_params

  tags = var.generic_info.custom_tags
}
