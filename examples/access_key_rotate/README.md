<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                      | Version  |
|---------------------------------------------------------------------------|----------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 4.0.0 |

## Providers

| Name                                              | Version |
|---------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.21.0  |

## Modules

| Name                                                                                                          | Source            | Version |
|---------------------------------------------------------------------------------------------------------------|-------------------|---------|
| <a name="module_lambda_accesskey_rotate"></a> [lambda\_accesskey\_rotate](#module\_lambda\_accesskey\_rotate) | ../..             | n/a     |
| <a name="module_secret_kms_key"></a> [secret\_kms\_key](#module\_secret\_kms\_key)                            | oozou/kms-key/aws | 1.0.0   |
| <a name="module_sns"></a> [sns](#module\_sns)                                                                 | oozou/sns/aws     | 1.0.1   |

## Resources

| Name                                                                                                                                                       | Type        |
|------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [aws_iam_policy.iam_updatekey_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                              | resource    |
| [aws_iam_policy.secretsmanager_updatesecret_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                | resource    |
| [aws_iam_policy.sns_publish_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                | resource    |
| [aws_iam_user.s3_presigned_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user)                                     | resource    |
| [aws_secretsmanager_secret.accesskey](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)                   | resource    |
| [aws_secretsmanager_secret_rotation.accesskey](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource    |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                                 | data source |
| [aws_iam_policy_document.lambda_access_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)     | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                                   | data source |

## Inputs

| Name                                                                     | Description                                                                                                                                                                                                                                                                                                                                                       | Type                                                                                                                                          | Default | Required |
|--------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| <a name="input_generic_info"></a> [generic\_info](#input\_generic\_info) | `prefix`      >> The prefix name of customer to be displayed in AWS console and resource<br>  `environment` >> Environment Variable used as a prefix<br>  `name`        >> Name of the ECS cluster and s3 also redis to create<br>  `custom_tags` >> Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys | <pre>object({<br>    prefix      = string<br>    environment = string<br>    name        = string<br>    custom_tags = map(any)<br>  })</pre> | n/a     |   yes    |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
