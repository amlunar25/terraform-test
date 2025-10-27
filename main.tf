module "network" {
  source                = "./modules/network"
  vpc_cidr              = "10.0.0.0/16"
  public_a_subnet_cidr  = "10.0.1.0/24"
  public_b_subnet_cidr  = "10.0.2.0/24"
  private_a_subnet_cidr = "10.0.3.0/24"
  private_b_subnet_cidr = "10.0.4.0/24"
  az_1                  = "us-east-2a"
  az_2                  = "us-east-2b"
  tag_name              = "vpc-test"
}

# Security Groups
module "security" {
  source = "./modules/security"
  vpc_id = module.network.vpc_id
}

# s3
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-private-bucket-terraform-test-nanlab1"
}

# Lambda
module "lambda_s3" {
  source               = "./modules/lambda_s3"
  lambda_function_name = "s3-to-postgres"
  lambda_filename      = "lambda.zip"
  lambda_handler       = "lambda_function.handler"
  lambda_runtime       = "python3.11"
  lambda_iam_role      = aws_iam_role.lambda_exec.arn
  private_subnet_id    = module.network.private_a_subnet_id
  lambda_sg_id         = module.security.lambda_sg_id
  rds_address          = module.rds.rds_endpoint
  lambda_env_vars = {
    DB_HOST     = module.rds.rds_endpoint
    DB_NAME     = "testdb"
    DB_USER     = "test"
    DB_PASSWORD = "test1234"
    DB_PORT     = "5432"
  }
}

# Allow S3 to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_s3.lambda_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.my_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notify" {
  bucket = aws_s3_bucket.my_bucket.id

  lambda_function {
    lambda_function_arn = module.lambda_s3.lambda_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [module.lambda_s3]
}

# RDS
module "rds" {
  source             = "./modules/rds"
  private_subnet_ids = [module.network.private_a_subnet_id]
  rds_sg_id          = module.security.rds_sg_id
  rds_tag_name       = "rds-postgres"
  # enable_gis = true
}


# API Gateway
module "api_gateway" {
  source      = "./modules/api_gateway"
  lambda_arn  = module.lambda_s3.lambda_arn
  lambda_name = module.lambda_s3.lambda_name
}