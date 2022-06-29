/* -------------------------------------------------------------------------- */
/*                                   Generic                                  */
/* -------------------------------------------------------------------------- */
variable "name" {
  description = "Name of the ECS cluster to create"
  type        = string
}

variable "environment" {
  description = "Environment Variable used as a prefix"
  type        = string
}

variable "prefix" {
  description = "The prefix name of customer to be displayed in AWS console and resource"
  type        = string
}

variable "tags" {
  description = "Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys"
  type        = map(any)
  default     = {}
}

/* -------------------------------------------------------------------------- */
/*                                    Data                                    */
/* -------------------------------------------------------------------------- */
variable "compressed_local_file_dir" {
  description = "A path to the directory to store plan time generated local files"
  type        = string
  default     = ""
}

variable "source_code_dir" {
  description = "An absolute path to the directory containing the code to upload to lambda"
  type        = string
  default     = ""
}

variable "file_globs" {
  description = "list of files or globs that you want included from the source_code_dir"
  type        = list(string)
  default     = []
  # default     = ["index.js", "node_modules/**", "yarn.lock", "package.json"]
}

variable "plaintext_params" {
  description = <<EOF
  Lambda@Edge does not support env vars, so it is a common pattern to exchange Env vars for values read from a config file.
  ! PLAINTEXT

  ```
  const config = JSON.parse(readFileSync('./config.json'))
  const someConfigValue = config.SomeKey
  ```
  EOF
  type        = map(string)
  default     = {}
}

variable "config_file_name" {
  description = "The name of the file var.plaintext_params will be written to as json"
  type        = string
  default     = "config.json"
}
/* -------------------------------------------------------------------------- */
/*                            Resource Based Policy                           */
/* -------------------------------------------------------------------------- */
variable "lambda_permission_configuration" {
  description = <<EOF
  principal  - (Required) The principal who is getting this permission e.g., s3.amazonaws.com, an AWS account ID, or any valid AWS service principal such as events.amazonaws.com or sns.amazonaws.com.
  source_arn - (Optional) When the principal is an AWS service, the ARN of the specific resource within that service to grant permission to. Without this, any resource from
  source_account - (Optional) This parameter is used for S3 and SES. The AWS account ID (without a hyphen) of the source owner.
  EOF
  type        = any
  default     = {}
}

/* -------------------------------------------------------------------------- */
/*                                     IAM                                    */
/* -------------------------------------------------------------------------- */
variable "is_create_lambda_role" {
  description = "Whether to create lamda role or not"
  type        = bool
  default     = true
}

variable "lambda_role_arn" {
  description = "The arn of role that already created by something to asso with lambda"
  type        = string
  default     = ""
}

variable "additional_lambda_role_policy_arns" {
  description = "List of policies ARNs to attach to the lambda"
  type        = list(string)
  default     = []
}

/* -------------------------------------------------------------------------- */
/*                            S3 Lambda Source Code                           */
/* -------------------------------------------------------------------------- */
variable "is_upload_form_s3" {
  description = "Whether to upload the source code from s3 or not"
  type        = bool
  default     = true
}

variable "file_name" {
  description = "The compressed file name used to upload to lambda use when is_upload_form_s3 is true"
  type        = string
  default     = ""
}

variable "is_create_lambda_bucket" {
  description = "Whether to create lambda bucket or not"
  type        = bool
  default     = false
}

variable "bucket_name" {
  description = "Name of the bucket to put the file in. Alternatively, an S3 access point ARN can be specified."
  type        = string
  default     = ""
}
/* -------------------------------------------------------------------------- */
/*                               Lambda Function                              */
/* -------------------------------------------------------------------------- */
variable "is_edge" {
  description = "Whether lambda is lambda@Edge or not"
  type        = bool
  default     = false
}

variable "timeout" {
  description = "(Optional) Amount of time your Lambda Function has to run in seconds. Defaults to 3."
  type        = number
  default     = 3
}

variable "memory_size" {
  description = "(Optional) Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128."
  type        = number
  default     = 128
}

variable "reserved_concurrent_executions" {
  description = "(Optional) Amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1. See Managing Concurrency"
  type        = number
  default     = -1
}

variable "vpc_config" {
  description = <<EOF
  For network connectivity to AWS resources in a VPC, specify a list of security groups and subnets in the VPC.
  When you connect a function to a VPC, it can only access resources and the internet through that VPC. See VPC Settings.

  security_group_ids - (Required) List of security group IDs associated with the Lambda function.
  subnet_ids_to_associate - (Required) List of subnet IDs associated with the Lambda function.
  EOF
  type = object({
    security_group_ids      = list(string)
    subnet_ids_to_associate = list(string)
  })
  default = {
    security_group_ids      = []
    subnet_ids_to_associate = []
  }
}

variable "dead_letter_target_arn" {
  description = "Dead letter queue configuration that specifies the queue or topic where Lambda sends asynchronous events when they fail processing."
  type        = string
  default     = null
}

variable "runtime" {
  description = "The runtime of the lambda function"
  type        = string
}

variable "handler" {
  description = "Function entrypoint in your code."
  type        = string
  default     = "index.handler"
}

/* -------------------------------------------------------------------------- */
/*                            CloudWatch Log Group                            */
/* -------------------------------------------------------------------------- */
variable "is_create_cloudwatch_log_group" {
  description = "Whether to create cloudwatch log group or not"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "Retention day for cloudwatch log group"
  type        = number
  default     = 90
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key."
  type        = string
  default     = ""
}

variable "ssm_params" {
  description = <<EOF
  Lambda@Edge does not support env vars, so it is a common pattern to exchange Env vars for SSM params.
  ! SECRET

  you would have lookups in SSM, like:
  `const someEnvValue = await ssmClient.getParameter({ Name: 'SOME_SSM_PARAM_NAME', WithDecryption: true })`

  EOF
  type        = map(string)
  default     = {}
}
