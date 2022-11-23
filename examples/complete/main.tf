module "lambda" {
  source = "../../"

  prefix      = var.prefix
  environment = var.environment
  name        = var.name

  is_edge = false # Defautl is `false`, If you want to publish to the edge don't forget to override aws's provider to virgina

  # If is_edge is `false`, ignore this config
  is_create_lambda_bucket = true # Default is `false`; plz use false, if not 1 lambda: 1 bucket
  bucket_name             = ""   # If `is_create_lambda_bucket` is `false`; specified this, default is `""`

  # Source code
  source_code_dir           = "./src"
  file_globs                = ["index.js"]
  compressed_local_file_dir = "./outputs"

  # Lambda Env
  runtime = "nodejs12.x"
  handler = "index.handler"

  # Lambda Specification
  timeout                        = 3
  memory_size                    = 128
  reserved_concurrent_executions = -1

  # Optional to connect Lambda to VPC
  vpc_config = {
    security_group_ids      = ["sg-028f637312eea735e"]
    subnet_ids_to_associate = ["subnet-0b853f8c85796d72d", "subnet-07c068b4b51262793", "subnet-0362f68c559ef7716"]
  }
  dead_letter_target_arn = "arn:aws:sns:ap-southeast-1:557291035693:demo" # To send failed processing to target, Default is `""`

  # IAM
  is_create_lambda_role = true # Default is `true`
  lambda_role_arn       = ""   # If `is_create_lambda_role` is `false`
  # The policies that you want to attach to IAM Role created by only this module                                                   # If `is_create_lambda_role` is `false`
  additional_lambda_role_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]

  # Resource policy
  lambda_permission_configurations = {
    lambda_on_my_account = {
      pricipal   = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:ap-southeast-1:557291035112:lk36vflbha/*/*/"
    }
    lambda_on_my_another_account_wrong = {
      pricipal       = "apigateway.amazonaws.com"
      source_arn     = "arn:aws:execute-api:ap-southeast-1:224563527112:q6pwa6wgr6/*/*/"
      source_account = "557291035112"
    }
    lambda_on_my_another_account_correct = {
      pricipal   = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:ap-southeast-1:557291035112:wpj4t3scmb/*/*/"
    }
  }

  # Logging
  is_create_cloudwatch_log_group   = true # Default is `true`
  cloudwatch_log_retention_in_days = 90   # Default is `90`

  # Env
  ssm_params = {}
  plaintext_params = {
    region         = "ap-southeast-1"
    cluster_name   = "oozou-dev-test-schedule-cluster"
    nodegroup_name = "oozou-dev-test-schedule-custom-nodegroup"
    min            = 1,
    max            = 1,
    desired        = 1
  }

  tags = var.custom_tags
}
