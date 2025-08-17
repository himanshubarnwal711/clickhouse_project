variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "efs_security_group_id" {
  description = "Security group that allows NFS (2049) from ECS tasks"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
