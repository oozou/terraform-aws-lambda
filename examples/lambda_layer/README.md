<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                      | Version           |
|---------------------------------------------------------------------------|-------------------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0          |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 4.0.0, < 5.0.0 |

## Providers

| Name                                              | Version           |
|---------------------------------------------------|-------------------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0, < 5.0.0 |

## Modules

| Name                                                   | Source | Version |
|--------------------------------------------------------|--------|---------|
| <a name="module_lambda"></a> [lambda](#module\_lambda) | ../../ | n/a     |

## Resources

| Name                                                                                                                                      | Type     |
|-------------------------------------------------------------------------------------------------------------------------------------------|----------|
| [aws_lambda_layer_version.lambda_layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |

## Inputs

| Name                                                                     | Description                                                                                                                                                                                                                                                                                                                                                       | Type                                                                                                                                          | Default | Required |
|--------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| <a name="input_generic_info"></a> [generic\_info](#input\_generic\_info) | `prefix`      >> The prefix name of customer to be displayed in AWS console and resource<br>  `environment` >> Environment Variable used as a prefix<br>  `name`        >> Name of the ECS cluster and s3 also redis to create<br>  `custom_tags` >> Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys | <pre>object({<br>    prefix      = string<br>    environment = string<br>    name        = string<br>    custom_tags = map(any)<br>  })</pre> | n/a     |   yes    |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
