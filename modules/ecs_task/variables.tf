variable "family" {
  description = "The ECS task definition family"
  type        = string
}

variable "cpu" {
  description = "CPU units for the task"
  type        = number
}

variable "memory" {
  description = "Memory in MB for the task"
  type        = number
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 8123
}

variable "image" {
  description = "Image URI for the container"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "clickhouse_user" {
  description = "ClickHouse user"
  type        = string
}

variable "clickhouse_password" {
  description = "ClickHouse password"
  type        = string
  sensitive   = true
}

variable "clickhouse_default_access_management" {
  description = "ClickHouse default access management flag"
  type        = string
}

variable "log_group" {
  description = "CloudWatch Logs group name"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}
