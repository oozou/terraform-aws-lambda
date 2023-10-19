variable "generic_info" {
  description = <<EOF
  `prefix`      >> The prefix name of customer to be displayed in AWS console and resource
  `environment` >> Environment Variable used as a prefix
  `name`        >> Name of the ECS cluster and s3 also redis to create
  `custom_tags` >> Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys
  EOF
  type = object({
    prefix      = string
    environment = string
    name        = string
    custom_tags = map(any)
  })
}
