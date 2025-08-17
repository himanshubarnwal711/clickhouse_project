variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1"
}

variable "env" {
  description = "The environment for the deployment (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

variable "asset_id" {
  description = "LSEG Asset ID for the deployment."
  type        = string
  default     = "a552762"
}

variable "app_code" {
  description = "Application code for the deployment."
  type        = string
  default     = "service-layer-poc-clickhouse"
}

variable "project_name" {
  description = "Name of the project to prefix resources"
  type        = string
}

variable "container_name" {
  description = "Name of the ECS container"
  type        = string
}

