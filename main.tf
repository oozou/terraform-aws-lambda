/* -------------------------------------------------------------------------- */
/*                                   Generic                                  */
/* -------------------------------------------------------------------------- */
locals {
  name = format("%s-%s-%s", var.prefix, var.environment, var.name)

  lambda_role_arn = var.is_create_lambda_role ? aws_iam_role.this[0].arn : var.lambda_role_arn

  tags = merge(
    {
      "Environment" = var.environment,
      "Terraform"   = "true"
    },
    var.tags
  )
}
/* ----------------------------- Raise Exception ---------------------------- */
locals {
  raise_is_lambda_role_arn_empty = var.is_create_lambda_role == false && var.lambda_role_arn == "" ? file("Variable `lambda_role_arn` is required when `is_create_lambda_role` is false") : "pass"
}

/* -------------------------------------------------------------------------- */
/*                                     S3                                     */
/* -------------------------------------------------------------------------- */
/* -------------------------------- ZIP File -------------------------------- */
data "archive_file" "zip_file" {
  type        = "zip"
  output_path = format("%s/%s.zip", var.local_file_dir, local.name)

  dynamic "source" {
    for_each = distinct(flatten([for blob in var.file_globs : fileset(var.source_code_dir, blob)]))
    content {
      content = try(
        file(
          format("%s/%s", var.source_code_dir, source.value)
        ),
        filebase64(
          format("%s/%s", var.source_code_dir, source.value)
        ),
      )
      filename = source.value
    }
  }

  # Optionally write a `config.json` file if any plaintext params were given
  dynamic "source" {
    for_each = length(keys(var.plaintext_params)) > 0 ? ["true"] : []
    content {
      content  = jsonencode(var.plaintext_params)
      filename = var.config_file_name
    }
  }
}

module "s3" {
  count = var.is_create_lambda_bucket ? 1 : 0

  source = "git@github.com:oozou/terraform-aws-s3.git?ref=v1.0.2"

  prefix      = var.prefix
  environment = var.environment
  bucket_name = var.is_edge ? format("%s-lambda-edge-bucket", var.name) : format("%s-lambda-bucket", var.name)

  force_s3_destroy = true

  is_enable_s3_hardening_policy      = false
  is_create_consumer_readonly_policy = false

  tags = var.tags
}

resource "aws_s3_object" "this" {
  bucket = var.is_create_lambda_bucket ? element(module.s3[*].bucket_name, 0) : var.bucket_name
  key    = format("%s.zip", local.name)
  source = data.archive_file.zip_file.output_path
  etag   = data.archive_file.zip_file.output_md5

  tags = merge(local.tags, { "Name" = format("%s.zip", local.name) })
}

/* -------------------------------------------------------------------------- */
/*                            Resource Based Policy                           */
/* -------------------------------------------------------------------------- */
resource "aws_lambda_permission" "allow_serivce" {
  for_each = var.lambda_permission_configuration

  statement_id   = format("AllowExecutionFrom-%s", each.key)
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.this.function_name
  principal      = lookup(each.value, "pricipal", null)
  source_arn     = lookup(each.value, "source_arn", null)
  source_account = lookup(each.value, "source_account", null)
  # principal_org_id = lookup(each.value, "principal_org_id", "")
  # Terraform aws says not support by doc support
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission#principal_org_id
}

/* -------------------------------------------------------------------------- */
/*                                  IAM Role                                  */
/* -------------------------------------------------------------------------- */
data "aws_iam_policy_document" "assume_role_policy_doc" {
  count = var.is_create_lambda_role ? 1 : 0

  statement {
    sid    = "AllowAwsToAssumeRole"
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = var.is_edge ? [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com",
        ] : [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda_logs_policy_doc" {
  count = var.is_create_lambda_role ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambda_access_vpc" {
  count = var.is_create_lambda_role ? 1 : 0

  # Allow to connect to VPC
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  count = var.is_create_lambda_role ? 1 : 0

  source_policy_documents = [
    data.aws_iam_policy_document.lambda_logs_policy_doc[0].json,
    data.aws_iam_policy_document.lambda_access_vpc[0].json
  ]
}

resource "aws_iam_role" "this" {
  count = var.is_create_lambda_role ? 1 : 0

  name               = format("%s-function-role", local.name)
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_doc[0].json

  tags = merge(local.tags, { "Name" : format("%s-function-role", local.name) })
}

resource "aws_iam_role_policy" "logs_role_policy" {
  count = var.is_create_lambda_role ? 1 : 0

  name   = var.is_edge ? format("%s-lambda-at-edge-log-access-policy", local.name) : format("%s-lambda-log-access-policy", local.name)
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.lambda_policy[0].json
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.is_create_lambda_role ? toset(var.additional_lambda_role_policy_arns) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

/* -------------------------------------------------------------------------- */
/*                                     SSM                                    */
/* -------------------------------------------------------------------------- */
resource "aws_ssm_parameter" "params" {
  for_each = var.ssm_params

  description = format("param %s for the lambda function %s", each.key, local.name)

  name  = each.key
  value = each.value

  type = "SecureString"
  tier = length(each.value) > 4096 ? "Advanced" : "Standard"

  tags = var.tags
}

data "aws_iam_policy_document" "secret_access_policy_doc" {
  count = var.is_create_lambda_role && length(var.ssm_params) > 0 ? 1 : 0

  statement {
    sid    = "AccessParams"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      for name, outputs in aws_ssm_parameter.params :
      outputs.arn
    ]
  }
}

resource "aws_iam_policy" "ssm_policy" {
  count = var.is_create_lambda_role && length(var.ssm_params) > 0 ? 1 : 0

  name        = format("%s-ssm-policy", local.name)
  description = format("Gives the lambda %s access to params from SSM", local.name)
  policy      = data.aws_iam_policy_document.secret_access_policy_doc[0].json
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  count = var.is_create_lambda_role && length(var.ssm_params) > 0 ? 1 : 0

  role       = aws_iam_role.this[0].id
  policy_arn = aws_iam_policy.ssm_policy[0].arn
}

/* -------------------------------------------------------------------------- */
/*                               Lambda Function                              */
/* -------------------------------------------------------------------------- */
resource "aws_lambda_function" "this" {
  function_name = format("%s-function", local.name)
  description   = format("Lambda function: %s", local.name)

  # Read the file from s3
  s3_bucket         = var.is_create_lambda_bucket ? element(module.s3[*].bucket_name, 0) : var.bucket_name
  s3_key            = aws_s3_object.this.id
  s3_object_version = aws_s3_object.this.version_id
  source_code_hash  = filebase64sha256(data.archive_file.zip_file.output_path)

  # Specification
  timeout                        = var.timeout
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions

  vpc_config {
    security_group_ids = var.vpc_config.security_group_ids
    subnet_ids         = var.vpc_config.subnet_ids_to_associate
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn == null ? [] : [true]
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  # Code Env
  publish = true # Force public new version
  runtime = var.runtime
  handler = var.handler

  role = local.lambda_role_arn

  lifecycle {
    ignore_changes = [
      last_modified,
    ]
  }

  tags = merge(local.tags, { "Name" = format("%s-function", local.name) })
}

/* -------------------------------------------------------------------------- */
/*                            CloudWatch Log Group                            */
/* -------------------------------------------------------------------------- */
resource "aws_cloudwatch_log_group" "this" {
  count = var.is_create_cloudwatch_log_group ? 1 : 0

  name              = format("/aws/lambda/%s-function", local.name)
  retention_in_days = var.retention_in_days

  tags = merge(local.tags, { "Name" = format("/aws/lambda/%s-function", local.name) })
}
