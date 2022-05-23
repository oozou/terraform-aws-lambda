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
variable "local_file_dir" {
  description = "A path to the directory to store plan time generated local files"
  type        = string
}

variable "source_code_dir" {
  description = "An absolute path to the directory containing the code to upload to lambda"
  type        = string
}

variable "file_globs" {
  description = "list of files or globs that you want included from the source_code_dir"
  type        = list(string)
  # default     = ["index.js", "node_modules/**", "yarn.lock", "package.json"]
}

variable "plaintext_params" {
  description = <<EOF
  Lambda@Edge does not support env vars, so it is a common pattern to exchange Env vars for values read from a config file.

  So instead of using env vars like:
  `const someEnvValue = process.env.SOME_ENV`

  you would have lookups from a config file:
  ```
  const config = JSON.parse(readFileSync('./config.json'))
  const someConfigValue = config.SomeKey
  ```

  Compared to var.ssm_params, you should use this variable when you have non-secret things that you want very quick access
  to during the execution of your lambda function.
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

variable "retention_in_days" {
  description = "Retention day for cloudwatch log group"
  type        = number
  default     = 30
}


variable "ssm_params" {
  description = <<EOF
  Lambda@Edge does not support env vars, so it is a common pattern to exchange Env vars for SSM params.

  So instead of using env vars like:
  `const someEnvValue = process.env.SOME_ENV`

  you would have lookups in SSM, like:
  `const someEnvValue = await ssmClient.getParameter({ Name: 'SOME_SSM_PARAM_NAME', WithDecryption: true })`

  These params should have names that are unique within an AWS account, so it is a good idea to use a common
  prefix in front of the param names, such as:

  ```
  params = {
    COMMON_PREFIX_REGION = "eu-west-1"
    COMMON_PREFIX_NAME   = "Joeseph Schreibvogel"
  }
  ```

  Compared to var.plaintext_params, you should use this variable when you have secret data that you don't want written in plaintext in a file
  in your lambda .zip file. These params will need to be fetched via a Promise at runtime, so there may be small performance delays.
  EOF
  type        = map(string)
  default     = {}
}
