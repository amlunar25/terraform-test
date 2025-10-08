variable "private_subnet_ids" {}
variable "rds_sg_id" {}
variable "rds_engine" {default = "postgres"}
variable "rds_engine_version" {default = "15.13"}
variable "rds_instance_class" {default = "db.t3.micro"}
variable "rds_db" {default = "testdb"}
variable "rds_db_user" {default = "test"}
variable "rds_db_pass" {default = "test1234"}
variable "rds_tag_name" {default = "rds-postgres"}
variable "enable_gis" {
  description = "Enable PostGIS extension after RDS creation"
  type        = bool
  default     = false
}