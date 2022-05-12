/* -------------------------------------------------------------------------- */
/*                                   Generic                                  */
/* -------------------------------------------------------------------------- */
locals {
  name = format("%s-%s-%s", var.prefix, var.environment, var.name)

  tags = merge(
    {
      "Environment" = var.environment,
      "Terraform"   = "true"
    },
    var.tags
  )
}

/* -------------------------------------------------------------------------- */
/*                                     S3                                     */
/* -------------------------------------------------------------------------- */
/* -------------------------------- ZIP File -------------------------------- */
# Since Lambdas are uploaded via zip files, we produce a zip file from a provided directory.
# In the future, we might source our code from an S3 bucket rather than a local zip file.
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

# Upload the build artifact zip file to S3.
# Doing this makes the plans more resiliant, where it won't always
# appear that the function needs to be updated
module "s3" {
  count = var.is_create_lambda_bucket ? 1 : 0

  source = "git@github.com:oozou/terraform-aws-s3.git?ref=v1.0.2"

  prefix      = var.prefix
  environment = var.environment
  bucket_name = format("%s-lambda-bucket", var.name)

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
/*                                  IAM Role                                  */
/* -------------------------------------------------------------------------- */
# Permit AWS access to this lambda function.
data "aws_iam_policy_document" "assume_role_policy_doc" {
  statement {
    sid    = "AllowAwsToAssumeRole"
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }
  }
}
# Permit lambda to write logs.
data "aws_iam_policy_document" "lambda_logs_policy_doc" {
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
# Create a role that AWS services can adopt to enable the invocation of our function.
# Additionally, this policy has the ability to write logs to CloudWatch.
resource "aws_iam_role" "this" {
  name               = format("%s-function-role", local.name)
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_doc.json

  tags = merge(local.tags, { "Name" : format("%s-function-role", local.name) })
}
# Attach the policy granting IAM Role log write access.
resource "aws_iam_role_policy" "logs_role_policy" {
  name   = format("%s-lambda-at-edge-log-access-policy", local.name)
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.lambda_logs_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.additional_lambda_role_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
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

  publish = true
  runtime = var.runtime
  handler = var.handler
  role    = aws_iam_role.this.arn

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

  name              = format("%s-lambda-log-group", local.name)
  retention_in_days = var.retention_in_days

  tags = merge(local.tags, { "Name" = format("%s-lambda-log-group", local.name) })
}

/* -------------------------------------------------------------------------- */
/*                                     SSM                                    */
/* -------------------------------------------------------------------------- */
# Create the secret SSM parameters that the lambda function can retrieve and decode.
resource "aws_ssm_parameter" "params" {
  for_each = var.ssm_params

  description = format("param %s for the lambda function %s", each.key, local.name)

  name  = each.key
  value = each.value

  type = "SecureString"
  tier = length(each.value) > 4096 ? "Advanced" : "Standard"

  tags = var.tags
}

# Create an IAM policy document that grants permission to read and retrieve SSM parameters.
data "aws_iam_policy_document" "secret_access_policy_doc" {
  count = length(var.ssm_params) > 0 ? 1 : 0

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

# Create a policy from the SSM policy document
resource "aws_iam_policy" "ssm_policy" {
  count = length(var.ssm_params) > 0 ? 1 : 0

  name        = format("%s-ssm-policy", local.name)
  description = format("Gives the lambda %s access to params from SSM", local.name)
  policy      = data.aws_iam_policy_document.secret_access_policy_doc[0].json
}


# Attach the policy giving SSM param access to the Lambda IAM Role
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  count = length(var.ssm_params) > 0 ? 1 : 0

  role       = aws_iam_role.this.id
  policy_arn = aws_iam_policy.ssm_policy[0].arn
}
