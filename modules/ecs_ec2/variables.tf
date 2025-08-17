variable "name_prefix" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = null
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecs_instance_sg_id" {
  description = "Security group for EC2 container instances (allow outbound and required inbound)"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "min_size" {
  type    = number
  default = 2
}
variable "max_size" {
  type    = number
  default = 4
}
variable "desired_capacity" {
  type    = number
  default = 2
}

variable "key_name" {
  type    = string
  default = "" # Bottlerocket typically not used with SSH; keep empty or set your key if needed
}

variable "tags" {
  type    = map(string)
  default = {}
}
