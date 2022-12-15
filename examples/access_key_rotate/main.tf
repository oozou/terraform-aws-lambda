locals {
  name              = format("%s-%s-%s", "oozou", "test", "app")
}

data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

/* -------------------------------------------------------------------------- */
/*                              SNS Notification                              */
/* -------------------------------------------------------------------------- */
data "aws_iam_policy_document" "lambda_access_kms_policy" {
  statement {
    sid    = "AllowLambdaToPublishMessageToEncryptedSNS"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]
    resources = ["*"]
    principals {
      identifiers = ["cloudwatch.amazonaws.com", "events.amazonaws.com"]
      type        = "Service"
    }
  }
}

# TODO fix KMS naming in SNS module
module "sns" {
  source  = "oozou/sns/aws"
  version = "1.0.1"

  prefix       = "oozou"
  environment  = "test"
  name         = format("%s-accesskey-rotate", "app") 
  display_name = "Alerting Center"

  sns_permission_configuration = {
    allow_cloudwatch_to_publish_alert = {
      pricipal = "cloudwatch.amazonaws.com"
    }
    allow_eventbridge_to_publish_alert = {
      pricipal = "events.amazonaws.com"
    }
  }

  subscription_configurations = {
    oozou_admin = {
      protocol  = "email"
      addresses = ["xxx@xxx.com"]
      # filter_policy = jsonencode(var.admin_filter_polciy)
    }
  }

  additional_kms_key_policies = [data.aws_iam_policy_document.lambda_access_kms_policy.json]

  tags = {}
}

/* -------------------------------------------------------------------------- */
/*                                   Lambda                                   */
/* -------------------------------------------------------------------------- */

resource "aws_iam_policy" "sns_publish_policy" {
  name = format("%s-sns-publish-access", local.name)
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:Publish",
        ]
        Effect   = "Allow"
        "Resource": module.sns.sns_topic_arn
      },
    ]
  })
}

resource "aws_iam_policy" "iam_updateKey_policy" {
  name = format("%s-iam-updatekey-access", local.name)
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:CreateAccessKey",
          "iam:UpdateAccessKey",
          "iam:ListAccessKeys",
          "iam:DeleteAccessKey",
        ]
        Effect   = "Allow"
        "Resource": aws_iam_user.s3_presigned_user.arn
      },
    ]
  })
}

resource "aws_iam_policy" "secretsmanager_updatesecret_policy" {
  name = format("%s-secretsmanager-updatesecret-access", local.name)
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:PutSecretValue"
        ]
        Effect   = "Allow"
          "Resource": aws_secretsmanager_secret.accesskey.arn
      },
    ]
  })
}

module "lambda_accesskey_rotate" {
  source = "../.."

  prefix      = "oozou"
  environment = "test"
  name        = "accesskey_rotate"

  is_edge = false

  # Source code
  source_code_dir           = "./src"
  file_globs                = ["access_key_rotate.py"]
  compressed_local_file_dir = "./outputs"

  # Lambda Env
  runtime = "python3.9"
  handler = "access_key_rotate.handler"
  environment_variables = {
    iam_username    = aws_iam_user.s3_presigned_user.name
    secret_name      = aws_secretsmanager_secret.accesskey.name
    sns_topic_arn   = module.sns.sns_topic_arn
  }

  # IAM
  additional_lambda_role_policy_arns = [
    aws_iam_policy.sns_publish_policy.arn,
    aws_iam_policy.secretsmanager_updatesecret_policy.arn,
    aws_iam_policy.iam_updateKey_policy.arn
  ]

  # Resource policy
  lambda_permission_configurations = {
    allow_trigger_from_eventbridge = {
      principal   = "secretsmanager.amazonaws.com"
    }
  }


  tags = {}
}

/* -------------------------------------------------------------------------- */
/*                                   Secret                                   */
/* -------------------------------------------------------------------------- */

module "secret_kms_key" {
  source  = "oozou/kms-key/aws"
  version = "1.0.0"

  name                 = format("%s-service-secrets", "app")
  prefix               = "oozou"
  environment          = "test"
  key_type             = "service"
  append_random_suffix = true
  description          = format("Secure Secrets Manager's service secrets for service %s", "app")

  service_key_info = {
    aws_service_names  = tolist([format("secretsmanager.%s.amazonaws.com", data.aws_region.this.name)])
    caller_account_ids = tolist([data.aws_caller_identity.this.account_id])
  }

  tags = merge({}, { "Name" : format("%s-service-secrets", "app") })
}

resource "aws_secretsmanager_secret" "accesskey" {
  name                = format("%s/accesskey", local.name)
  description = "access key secret with rotation"
  kms_key_id  = module.secret_kms_key.key_arn
  recovery_window_in_days = 0

}

resource "aws_secretsmanager_secret_rotation" "accesskey" {
  secret_id           = aws_secretsmanager_secret.accesskey.id
  rotation_lambda_arn = module.lambda_accesskey_rotate.function_arn 
  rotation_rules {
    automatically_after_days = 7
  }
  depends_on = [
    module.lambda_accesskey_rotate
  ]
}

/* -------------------------------------------------------------------------- */
/*                                 IAM User                                   */
/* -------------------------------------------------------------------------- */


resource "aws_iam_user" "s3_presigned_user" {
  name = "s3_presigned_user"
  path = "/"

  tags = merge({}, { "Name" = "s3_presigned_user" })
}

