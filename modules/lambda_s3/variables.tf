variable "private_subnet_id" {}
variable "lambda_sg_id" {}
variable "rds_address" {}
variable "lambda_filename" {default = "lambda.zip"}
variable "lambda_function_name" {default = "s3-to-postgres"}
variable "lambda_handler" {default = "lambda_function.handler"}
variable "lambda_runtime" {default = "python3.11"}
variable "lambda_iam_role" {}
variable "lambda_env_vars" {} 