/* -------------------------------------------------------------------------- */
/*                                  Generics                                  */
/* -------------------------------------------------------------------------- */
variable "generic_info" {
  description = "Generic infomation"
  type = object({
    region      = string
    prefix      = string
    environment = string
    name        = string
    custom_tags = map(any)
  })
}

/* -------------------------------------------------------------------------- */
/*                                   Lambda                                   */
/* -------------------------------------------------------------------------- */
variable "is_edge" {
  description = "Whether lambda is lambda@Edge or not"
  type        = bool
  default     = false
}

variable "is_create_lambda_bucket" {
  description = "Whether to create lambda bucket or not"
  type        = bool
  default     = true
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

variable "is_create_lambda_role" {
  description = "Whether to create lamda role or not"
  type        = bool
  default     = true
}

variable "additional_lambda_role_policy_arns" {
  description = "Map of policies ARNs to attach to the lambda"
  type        = map(string)
  default     = {}
}

variable "lambda_permission_configurations" {
  description = <<EOF
  principal  - (Required) The principal who is getting this permission e.g., s3.amazonaws.com, an AWS account ID, or any valid AWS service principal such as events.amazonaws.com or sns.amazonaws.com.
  source_arn - (Optional) When the principal is an AWS service, the ARN of the specific resource within that service to grant permission to. Without this, any resource from
  source_account - (Optional) This parameter is used for S3 and SES. The AWS account ID (without a hyphen) of the source owner.
  EOF
  type        = any
  default     = {}
}

variable "is_create_cloudwatch_log_group" {
  description = "Whether to create cloudwatch log group or not"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_in_days" {
  description = "Retention day for cloudwatch log group"
  type        = number
  default     = 90
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
