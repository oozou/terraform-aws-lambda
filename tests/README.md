# Terraform AWS Lambda Module Tests

This directory contains the automated tests for the `terraform-aws-lambda` module. The tests are written in Go using the [Terratest](https://terratest.gruntwork.io/) framework.

## Running the Tests

To run the tests, navigate to this directory and run the following command:

```bash
go test -v -timeout 30m
```

## Test Scenarios

The following scenarios are covered by the tests:

### 1. `TestLambdaCreated`
Verifies that a Lambda function is successfully created by the module.

### 2. `TestLambdaConfiguration`
Checks that the created Lambda function has the correct configuration, including:
- Runtime
- Handler
- Timeout
- Memory size

### 3. `TestLambdaInvocation`
Invokes the created Lambda function with a sample payload and verifies that it returns a successful response.

### 4. `TestIAMRoleAndPolicies`
Ensures that an IAM role is created for the Lambda function and that it has the expected policies attached.

### 5. `TestVPCConfiguration`
Verifies that the Lambda function is correctly associated with the specified VPC, subnets, and security groups.

### 6. `TestEnvironmentVariables`
Checks that the environment variables defined in the Terraform configuration are correctly set on the Lambda function.

### 7. `TestCloudWatchLogs`
Confirms that a CloudWatch Log Group is created for the Lambda function with the correct retention period.

### 8. `TestLambdaVersioning`
Verifies that a new version of the Lambda function is published on each deployment.
