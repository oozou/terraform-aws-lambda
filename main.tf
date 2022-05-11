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
/*                                    Data                                    */
/* -------------------------------------------------------------------------- */
/* -------------------------------- ZIP File -------------------------------- */
# Lambdas are uploaded to via zip files, so we create a zip out of a given directory.
# In the future, we may want to source our code from an s3 bucket instead of a local zip.
data "archive_file" "zip_file" {
  type        = "zip"
  output_path = format("%s/%s.zip", var.local_file_dir, replace(var.local_file_name, ".zip", ""))

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

resource "aws_s3_object" "object" {
  bucket = var.is_create_lambda_bucket ? element(module.s3[*].bucket_name, 0) : var.bucket_name
  key    = format("%s.zip", replace(var.local_file_name, ".zip", ""))
  source = data.archive_file.zip_file.output_path
  etag   = data.archive_file.zip_file.output_md5

  tags = local.tags
}

