# terraform-aws-lambda-edge

## Usage

```terraform
module "lambda" {
  source = "<source>"

  prefix      = "oozou"
  environment = "test"
  name        = "jukkee"

  is_edge = false  # Default is `false`

  # File to read from
  source_code_dir = "./src"
  file_globs      = ["index.js"]

  # File to saved to
  local_file_dir = "./outputs"

  # S3 to upload source code to
  is_create_lambda_bucket = true # Default is `false`; plz use false, if not 1 lambda: 1 bucket
  bucket_name             = ""   # If `is_create_lambda_bucket` is `false`; specified this, default is `""`

  # Lambda Config
  runtime = "nodejs12.x"
  handler = "index.handler" # Default `"index.handler"`

  # IAM
  is_create_lambda_role              = true                                               # Default is `true`
  lambda_role_arn                    = ""                                                 # If `is_create_lambda_role` is `false`
  additional_lambda_role_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"] # The policies that you want to attach to IAM Role created by only this module

  # Resource policy
  lambda_permission_configuration = {
    lambda_on_my_account = {
      pricipal       = "apigateway.amazonaws.com"
      source_arn     = "arn:aws:execute-api:ap-southeast-1:557291035693:lk36vflbha/*/*/"
    }
    lambda_on_my_another_account_wrong = {
      pricipal       = "apigateway.amazonaws.com"
      source_arn     = "arn:aws:execute-api:ap-southeast-1:562563527952:q6pwa6wgr6/*/*/"
      source_account = "557291035693"  # Optional just to restrict the permission
    }
    lambda_on_my_another_account_correct = {
      pricipal   = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:ap-southeast-1:562563527952:q6pwa6wgr6/*/*/"
    }
  }

  # Logging
  is_create_cloudwatch_log_group = true # Default is `true`
  retention_in_days              = 30   # Default is `30`

  # Secret for lambda function
  ssm_params = {
    "DATABASE_PASSWORD" = "abdhegcg2365daA"
    "DATABASE_HOST"     = "www.google.com"
  }

  tags = { "Workspace" = "xxx-yyy-zzz" }
}

```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | 2.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.00 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.2.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.13.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3"></a> [s3](#module\_s3) | git@github.com:oozou/terraform-aws-s3.git | v1.0.2 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.logs_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ssm_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_serivce](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_object.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_ssm_parameter.params](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [archive_file.zip_file](https://registry.terraform.io/providers/hashicorp/archive/2.2.0/docs/data-sources/file) | data source |
| [aws_iam_policy_document.assume_role_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_logs_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.secret_access_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_lambda_role_policy_arns"></a> [additional\_lambda\_role\_policy\_arns](#input\_additional\_lambda\_role\_policy\_arns) | List of policies ARNs to attach to the lambda | `list(string)` | `[]` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the bucket to put the file in. Alternatively, an S3 access point ARN can be specified. | `string` | `""` | no |
| <a name="input_config_file_name"></a> [config\_file\_name](#input\_config\_file\_name) | The name of the file var.plaintext\_params will be written to as json | `string` | `"config.json"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Variable used as a prefix | `string` | n/a | yes |
| <a name="input_file_globs"></a> [file\_globs](#input\_file\_globs) | list of files or globs that you want included from the source\_code\_dir | `list(string)` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | Function entrypoint in your code. | `string` | `"index.handler"` | no |
| <a name="input_is_create_cloudwatch_log_group"></a> [is\_create\_cloudwatch\_log\_group](#input\_is\_create\_cloudwatch\_log\_group) | Whether to create cloudwatch log group or not | `bool` | `true` | no |
| <a name="input_is_create_lambda_bucket"></a> [is\_create\_lambda\_bucket](#input\_is\_create\_lambda\_bucket) | Whether to create lambda bucket or not | `bool` | `false` | no |
| <a name="input_is_create_lambda_role"></a> [is\_create\_lambda\_role](#input\_is\_create\_lambda\_role) | Whether to create lamda role or not | `bool` | `true` | no |
| <a name="input_is_edge"></a> [is\_edge](#input\_is\_edge) | Whether lambda is lambda@Edge or not | `bool` | `false` | no |
| <a name="input_lambda_permission_configuration"></a> [lambda\_permission\_configuration](#input\_lambda\_permission\_configuration) | principal  - (Required) The principal who is getting this permission e.g., s3.amazonaws.com, an AWS account ID, or any valid AWS service principal such as events.amazonaws.com or sns.amazonaws.com.<br>  source\_arn - (Optional) When the principal is an AWS service, the ARN of the specific resource within that service to grant permission to. Without this, any resource from<br>  source\_account - (Optional) This parameter is used for S3 and SES. The AWS account ID (without a hyphen) of the source owner. | `any` | `{}` | no |
| <a name="input_lambda_role_arn"></a> [lambda\_role\_arn](#input\_lambda\_role\_arn) | The arn of role that already created by something to asso with lambda | `string` | `""` | no |
| <a name="input_local_file_dir"></a> [local\_file\_dir](#input\_local\_file\_dir) | A path to the directory to store plan time generated local files | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the ECS cluster to create | `string` | n/a | yes |
| <a name="input_plaintext_params"></a> [plaintext\_params](#input\_plaintext\_params) | Lambda@Edge does not support env vars, so it is a common pattern to exchange Env vars for values read from a config file.<br>  ! PLAINTEXT<pre>const config = JSON.parse(readFileSync('./config.json'))<br>  const someConfigValue = config.SomeKey</pre> | `map(string)` | `{}` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix name of customer to be displayed in AWS console and resource | `string` | n/a | yes |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | Retention day for cloudwatch log group | `number` | `30` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The runtime of the lambda function | `string` | n/a | yes |
| <a name="input_source_code_dir"></a> [source\_code\_dir](#input\_source\_code\_dir) | An absolute path to the directory containing the code to upload to lambda | `string` | n/a | yes |
| <a name="input_ssm_params"></a> [ssm\_params](#input\_ssm\_params) | Lambda@Edge does not support env vars, so it is a common pattern to exchange Env vars for SSM params.<br>  ! SECRET<br><br>  you would have lookups in SSM, like:<br>  `const someEnvValue = await ssmClient.getParameter({ Name: 'SOME_SSM_PARAM_NAME', WithDecryption: true })` | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | Amazon Resource Name (ARN) identifying your Lambda Function. |
| <a name="output_execution_role_arn"></a> [execution\_role\_arn](#output\_execution\_role\_arn) | Role arn of lambda |
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | function arn |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Name of AWS Lambda function |
<!-- END_TF_DOCS -->
