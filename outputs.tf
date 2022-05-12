output "arn" {
  description = "Amazon Resource Name (ARN) identifying your Lambda Function."
  value       = format("%s:%s", aws_lambda_function.this.arn, aws_lambda_function.this.version)
}

output "function_arn" {
  value = aws_lambda_function.this.arn
}
output "function_name" {
  description = "Name of AWS Lambda function"
  value       = local.name
}

output "execution_role_name" {
  value = aws_iam_role.this.name
}

output "execution_role_arn" {
  value = aws_iam_role.this.arn
}
