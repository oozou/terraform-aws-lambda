/* -------------------------------------------------------------------------- */
/*                                  Generics                                  */
/* -------------------------------------------------------------------------- */
generic_info = {
  region      = "ap-southeast-1",
  prefix      = "oozou",
  environment = "devops",
  name        = "demo",
  custom_tags = {
    "Workspace" = "900-oozou-sandbox-terraform"
  }
}

/* -------------------------------------------------------------------------- */
/*                                   Lambda                                   */
/* -------------------------------------------------------------------------- */
# vpc_config = {
# security_group_ids      = ["sg-028f637312eea735e"]
# subnet_ids_to_associate = ["subnet-0b853f8c85796d72d", "subnet-07c068b4b51262793", "subnet-0362f68c559ef7716"]
# }

# dead_letter_target_arn = "arn:aws:sns:ap-southeast-1:557291035693:demo"

additional_lambda_role_policy_arns = {
  allow_lambda_to_read_s3 = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

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

plaintext_params = {
  region         = "ap-southeast-1"
  cluster_name   = "oozou-dev-test-schedule-cluster"
  nodegroup_name = "oozou-dev-test-schedule-custom-nodegroup"
  min            = 1,
  max            = 1,
  desired        = 1
}
