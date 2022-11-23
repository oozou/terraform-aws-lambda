# Change Log

All notable changes to this module will be documented in this file.

## [v1.1.3] - 2022-11-23

### Added

### Changed

- Update example usage for `examples/complete/*` and `examples/simple/*`
- Update meta-argument of resource `aws_iam_role_policy_attachment.this` from `for_each` to `count`
- Update variable `additional_lambda_role_policy_arns` from type `map(string)` to `list(string)`

### Removed

## [v1.1.2] - 2022-10-21

### Changed

- Update s3 module from version `v1.1.2` to public registry version `v1.1.3`

## [v1.1.1] - 2022-09-05

### Changed

- Update s3 module from version `v1.0.4` to public registry version `v1.1.2`

## [v1.1.0] - 2022-07-22

### Changed

- Remove upload code from s3
  - S3 source code is used for versioning
- Change `additional_lambda_role_policy_arn` to map from list

### Added

- Enable Tracing

## [v1.0.2] - 2022-07-01

### Added

- Add default log retention 90 days, KMS encryption support

### Fixed

- Fix kms security issue by @xshot9011 in #9

## [v1.0.1] - 2022-06-08

### Added

- Add resource base policy for lambda

## [v1.0.0] - 2022-05-17

### Added 

- Since Lambdas are uploaded via zip files, we generate a zip file from the path specified.
- Upload the zip file containing the build artifacts to S3.
- Allow access to this lambda function from AWS.
- Allow lambda to generate logs.
- Construct a role that AWS services can adopt in order to invoke our function.
- This policy also has the capability to write logs to CloudWatch.
- Create the secret SSM parameters that can be retrieved and decoded by the lambda function.
- Create an IAM policy document granting the ability to read and retrieve SSM parameter values.
- Develop a policy based on the SSM policy paper
- Custom policies to attach to this role
