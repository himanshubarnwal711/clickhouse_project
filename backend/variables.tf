variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "s3_bucket_name" {
  type    = string
  default = "service-layer-dev-poc-clickhouse-terraform-state"
}

variable "dynamodb_table_name" {
  type    = string
  default = "service-layer-poc-clickhouse-terraform-state"
}
