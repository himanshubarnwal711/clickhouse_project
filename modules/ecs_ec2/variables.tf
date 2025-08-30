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

variable "ami_id" {
  description = "The ID of the Amazon Machine Image (AMI) to use."
  type        = string
  default     = "ami-0861f4e788f5069dd" # -- "For Amazo Linux 2023 al2023-ami-2023.8.20250818.0-kernel-6.1-x86_64"
  # For ubuntu - "ami-02d26659fd82cf299" -- (x86_64 aarch and in ap-south-1 region)
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
