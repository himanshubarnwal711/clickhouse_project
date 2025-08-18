variable "service_name" {
  type        = string
  description = "Name prefix for service, task, ALB etc."
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "capacity_provider" {
  type        = string
  description = "ECS capacity provider name (if using one)"
}

variable "desired_count" {
  type        = number
  description = "Number of tasks desired"
  default     = 2
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs where tasks will run (ENI attachments)"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB"
}

variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "alb_sg" {
  type        = string
  description = "Security group ID to attach to ALB (must allow inbound :80 from where needed)"
}

variable "ecs_task_sg" {
  type        = string
  description = "Security group ID for ECS tasks (must allow inbound from alb_sg on container_port)"
}

variable "docker_image_uri" {
  type        = string
  description = "ECR image URI (with tag) for the container"
}

variable "container_name" {
  type        = string
  description = "Container name referenced by the service load_balancer block"
  default     = "app"
}

variable "container_port" {
  type        = number
  description = "Container port exposed by container"
  default     = 8123
}

variable "task_cpu" {
  type        = number
  description = "Task CPU units"
  default     = 512
}

variable "task_memory" {
  type        = number
  description = "Task memory (MB)"
  default     = 1024
}
