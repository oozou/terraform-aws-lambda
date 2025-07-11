output "function_name" {
  description = "Name of the Lambda function."
  value       = module.lambda.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = module.lambda.function_arn
}

output "execution_role_arn" {
  description = "ARN of the Lambda function's execution role."
  value       = module.lambda.execution_role_arn
}
