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

variable "local_file_name" {
  description = "The name of the stored file with `.zip` appended automatically."
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
  default     = "config.json"
}

/* -------------------------------------------------------------------------- */
/*                            S3 Lambda Source Code                           */
/* -------------------------------------------------------------------------- */
variable "is_create_lambda_bucket" {
  description = "Whether to create lambda bucket or not"
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "Name of the bucket to put the file in. Alternatively, an S3 access point ARN can be specified."
  type        = string
  default     = ""
}




