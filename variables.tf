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

variable "ami_id" {
  description = "The ID of the Amazon Machine Image (AMI) to use."
  type        = string
  default     = "ami-0861f4e788f5069dd" # -- "For Amazo Linux 2023 al2023-ami-2023.8.20250818.0-kernel-6.1-x86_64"
  # For ubuntu - "ami-02d26659fd82cf299" -- (x86_64 aarch and in ap-south-1 region)
}
