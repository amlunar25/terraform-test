output "lambda_arn" {
  value = aws_lambda_function.s3_to_postgres.arn
}

output "lambda_name" {
  value = aws_lambda_function.s3_to_postgres.function_name
}