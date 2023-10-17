/* -------------------------------------------------------------------------- */
/*                                    Local                                   */
/* -------------------------------------------------------------------------- */
locals {
  name = format("%s-%s-%s", var.generic_info.prefix, var.generic_info.environment, var.generic_info.name)
  tags = merge({ Terraform = true }, var.generic_info.custom_tags)
}

/* -------------------------------------------------------------------------- */
/*                                    Data                                    */
/* -------------------------------------------------------------------------- */
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

  tags = local.tags
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
        Effect = "Allow"
        "Resource" : module.sns.sns_topic_arn
      },
    ]
  })
}

resource "aws_iam_policy" "iam_updatekey_policy" {
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
        Effect = "Allow"
        "Resource" : aws_iam_user.s3_presigned_user.arn
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
        Effect = "Allow"
        "Resource" : aws_secretsmanager_secret.accesskey.arn
      },
    ]
  })
}

module "lambda_accesskey_rotate" {
  source = "../.."

  prefix      = var.generic_info.prefix
  environment = var.generic_info.environment
  name        = format("%s-accesskey-rotate", var.generic_info.name)

  # Source code
  source_code_dir           = "./src"
  compressed_local_file_dir = "./outputs"

  # Lambda Env
  runtime = "python3.9"
  handler = "access_key_rotate.handler"
  environment_variables = {
    iam_username  = aws_iam_user.s3_presigned_user.name
    secret_name   = aws_secretsmanager_secret.accesskey.name
    sns_topic_arn = module.sns.sns_topic_arn
  }

  # IAM
  additional_lambda_role_policy_arns = [
    aws_iam_policy.sns_publish_policy.arn,
    aws_iam_policy.secretsmanager_updatesecret_policy.arn,
    aws_iam_policy.iam_updatekey_policy.arn
  ]

  # Resource policy
  lambda_permission_configurations = {
    allow_trigger_from_eventbridge = {
      principal = "secretsmanager.amazonaws.com"
    }
  }

  tags = local.tags
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

  tags = local.tags
}

resource "aws_secretsmanager_secret" "accesskey" {
  name                    = format("%s/accesskey", local.name)
  description             = "access key secret with rotation"
  kms_key_id              = module.secret_kms_key.key_arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_rotation" "accesskey" {
  depends_on = [
    module.lambda_accesskey_rotate
  ]

  secret_id           = aws_secretsmanager_secret.accesskey.id
  rotation_lambda_arn = module.lambda_accesskey_rotate.function_arn
  rotation_rules {
    automatically_after_days = 7
  }
}

/* -------------------------------------------------------------------------- */
/*                                 IAM User                                   */
/* -------------------------------------------------------------------------- */
resource "aws_iam_user" "s3_presigned_user" {
  name = "s3_presigned_user"
  path = "/"

  tags = merge(local.tags, { "Name" = "s3_presigned_user" })
}
