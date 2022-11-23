module "lambda" {
  source = "../../"

  prefix      = var.prefix
  environment = var.environment
  name        = var.name

  source_code_dir           = "./src"
  file_globs                = ["index.js"]
  compressed_local_file_dir = "./outputs"

  runtime = "nodejs12.x"
  handler = "index.handler"

  additional_lambda_role_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
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
