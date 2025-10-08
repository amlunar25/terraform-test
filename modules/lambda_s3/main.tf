resource "aws_lambda_function" "s3_to_postgres" {
  filename      = var.lambda_filename
  function_name = var.lambda_function_name
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = var.lambda_iam_role

  vpc_config {
    subnet_ids         = [var.private_subnet_id]
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = var.lambda_env_vars
  }
}