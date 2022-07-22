# terraform-aws-lambda-edge

## Usage

```terraform
module "lambda" {
  source = "git@github.com:oozou/terraform-aws-lambda.git?ref=v1.0.2"

  prefix      = "oozou"
  environment = "dev"
  name        = "demo"

  is_edge = true # Defautl is `fault`, If you want to publish to the edge don't forget to override aws's provider to virgina

  # If is_edge is `false`, ignore this config
  is_create_lambda_bucket = true # Default is `false`; plz use false, if not 1 lambda: 1 bucket
  bucket_name             = ""   # If `is_create_lambda_bucket` is `false`; specified this, default is `""`

  # Source code
  source_code_dir           = "./src"
  file_globs                = ["main.py"]
  compressed_local_file_dir = "./outputs"

  # Lambda Env
  runtime = "python3.9"
  handler = "main.lambda_handler"

  # Lambda Specification
  timeout                        = 3   # Default is `3` seconds
  memory_size                    = 128 # Default is `128` MB, the more mem size increase, the performance is better
  reserved_concurrent_executions = -1
  # Optional to connect Lambda to VPC
  vpc_config = {
    security_group_ids      = ["sg-028f637312eea735e"]
    subnet_ids_to_associate = ["subnet-0b853f8c85796d72d", "subnet-07c068b4b51262793", "subnet-0362f68c559ef7716"]
  }
  dead_letter_target_arn = "arn:aws:sns:ap-southeast-1:557291035693:demo" # To send failed processing to target, Default is `""`

  # IAM
  is_create_lambda_role              = true                                                 # Default is `true`
  lambda_role_arn                    = ""
  # The policies that you want to attach to IAM Role created by only this module                                                   # If `is_create_lambda_role` is `false`
  additional_lambda_role_policy_arns = {
    allow_lambda_to_read_s3 = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  # Resource policy
  lambda_permission_configurations = {
    lambda_on_my_account = {
      pricipal   = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:ap-southeast-1:557291035693:lk36vflbha/*/*/"
    }
    lambda_on_my_another_account_wrong = {
      pricipal       = "apigateway.amazonaws.com"
      source_arn     = "arn:aws:execute-api:ap-southeast-1:562563527952:q6pwa6wgr6/*/*/"
      source_account = "557291035693" # Optional just to restrict the permission
    }
    lambda_on_my_another_account_correct = {
      pricipal   = "apigateway.amazonaws.com"
      source_arn = "arn:aws:execute-api:ap-southeast-1:557291035693:wpj4t3scmb/*/*/"
    }
  }

  # Logging
  is_create_cloudwatch_log_group = true # Default is `true`
  retention_in_days              = 30   # Default is `30`

  # Env
  ssm_params = {}
  plaintext_params = {
    region         = "ap-southeast-1"
    cluster_name   = "oozou-dev-test-schedule-cluster"
    nodegroup_name = "oozou-dev-test-schedule-custom-nodegroup"
    min            = 1,
    max            = 1,
    desired        = 1
  }

  tags = var.generics_info["custom_tags"]
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.23.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3"></a> [s3](#module\_s3) | git@github.com:oozou/terraform-aws-s3.git | v1.0.4 |

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
| [archive_file.this](https://registry.terraform.io/providers/hashicorp/archive/2.2.0/docs/data-sources/file) | data source |
| [aws_iam_policy_document.assume_role_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_access_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_logs_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.secret_access_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_lambda_role_policy_arns"></a> [additional\_lambda\_role\_policy\_arns](#input\_additional\_lambda\_role\_policy\_arns) | Map of policies ARNs to attach to the lambda | `map(string)` | `{}` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the bucket to put the file in. Alternatively, an S3 access point ARN can be specified. | `string` | `""` | no |
| <a name="input_cloudwatch_log_kms_key_id"></a> [cloudwatch\_log\_kms\_key\_id](#input\_cloudwatch\_log\_kms\_key\_id) | The ARN for the KMS encryption key. | `string` | `null` | no |
| <a name="input_cloudwatch_log_retention_in_days"></a> [cloudwatch\_log\_retention\_in\_days](#input\_cloudwatch\_log\_retention\_in\_days) | Retention day for cloudwatch log group | `number` | `90` | no |
| <a name="input_compressed_local_file_dir"></a> [compressed\_local\_file\_dir](#input\_compressed\_local\_file\_dir) | A path to the directory to store plan time generated local files | `string` | `""` | no |
| <a name="input_config_file_name"></a> [config\_file\_name](#input\_config\_file\_name) | The name of the file var.plaintext\_params will be written to as json | `string` | `"config.json"` | no |
| <a name="input_dead_letter_target_arn"></a> [dead\_letter\_target\_arn](#input\_dead\_letter\_target\_arn) | Dead letter queue configuration that specifies the queue or topic where Lambda sends asynchronous events when they fail processing. | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment Variable used as a prefix | `string` | n/a | yes |
| <a name="input_file_globs"></a> [file\_globs](#input\_file\_globs) | list of files or globs that you want included from the source\_code\_dir | `list(string)` | `[]` | no |
| <a name="input_handler"></a> [handler](#input\_handler) | Function entrypoint in your code. | `string` | n/a | yes |
| <a name="input_is_create_cloudwatch_log_group"></a> [is\_create\_cloudwatch\_log\_group](#input\_is\_create\_cloudwatch\_log\_group) | Whether to create cloudwatch log group or not | `bool` | `true` | no |
| <a name="input_is_create_lambda_bucket"></a> [is\_create\_lambda\_bucket](#input\_is\_create\_lambda\_bucket) | Whether to create lambda bucket or not | `bool` | `false` | no |
| <a name="input_is_create_lambda_role"></a> [is\_create\_lambda\_role](#input\_is\_create\_lambda\_role) | Whether to create lamda role or not | `bool` | `true` | no |
| <a name="input_is_edge"></a> [is\_edge](#input\_is\_edge) | Whether lambda is lambda@Edge or not | `bool` | `false` | no |
| <a name="input_lambda_permission_configurations"></a> [lambda\_permission\_configurations](#input\_lambda\_permission\_configurations) | principal  - (Required) The principal who is getting this permission e.g., s3.amazonaws.com, an AWS account ID, or any valid AWS service principal such as events.amazonaws.com or sns.amazonaws.com.<br>  source\_arn - (Optional) When the principal is an AWS service, the ARN of the specific resource within that service to grant permission to. Without this, any resource from<br>  source\_account - (Optional) This parameter is used for S3 and SES. The AWS account ID (without a hyphen) of the source owner. | `any` | `{}` | no |
| <a name="input_lambda_role_arn"></a> [lambda\_role\_arn](#input\_lambda\_role\_arn) | The arn of role that already created by something to asso with lambda | `string` | `""` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | (Optional) Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128. | `number` | `128` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the ECS cluster to create | `string` | n/a | yes |
| <a name="input_plaintext_params"></a> [plaintext\_params](#input\_plaintext\_params) | Lambda@Edge does not support env vars, so it is a common pattern to exchange Env vars for values read from a config file.<br>  ! PLAINTEXT<pre>const config = JSON.parse(readFileSync('./config.json'))<br>  const someConfigValue = config.SomeKey</pre> | `map(string)` | `{}` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix name of customer to be displayed in AWS console and resource | `string` | n/a | yes |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | (Optional) Amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1. See Managing Concurrency | `number` | `-1` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The runtime of the lambda function | `string` | n/a | yes |
| <a name="input_source_code_dir"></a> [source\_code\_dir](#input\_source\_code\_dir) | An absolute path to the directory containing the code to upload to lambda | `string` | `""` | no |
| <a name="input_ssm_params"></a> [ssm\_params](#input\_ssm\_params) | Lambda@Edge does not support env vars, so it is a common pattern to exchange Env vars for SSM params.<br>  ! SECRET<br><br>  you would have lookups in SSM, like:<br>  `const someEnvValue = await ssmClient.getParameter({ Name: 'SOME_SSM_PARAM_NAME', WithDecryption: true })` | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys | `map(any)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | (Optional) Amount of time your Lambda Function has to run in seconds. Defaults to 3. | `number` | `3` | no |
| <a name="input_tracing_mode"></a> [tracing\_mode](#input\_tracing\_mode) | Tracing mode of the Lambda Function. Valid value can be either PassThrough or Active. | `string` | `"PassThrough"` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | For network connectivity to AWS resources in a VPC, specify a list of security groups and subnets in the VPC.<br>  When you connect a function to a VPC, it can only access resources and the internet through that VPC. See VPC Settings.<br><br>  security\_group\_ids - (Required) List of security group IDs associated with the Lambda function.<br>  subnet\_ids\_to\_associate - (Required) List of subnet IDs associated with the Lambda function. | <pre>object({<br>    security_group_ids      = list(string)<br>    subnet_ids_to_associate = list(string)<br>  })</pre> | <pre>{<br>  "security_group_ids": [],<br>  "subnet_ids_to_associate": []<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | Amazon Resource Name (ARN) identifying your Lambda Function. |
| <a name="output_execution_role_arn"></a> [execution\_role\_arn](#output\_execution\_role\_arn) | Role arn of lambda |
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | function arn |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Name of AWS Lambda function |
<!-- END_TF_DOCS -->
