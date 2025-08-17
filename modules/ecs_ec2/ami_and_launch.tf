# Prefer using SSM parameter to fetch the Bottlerocket ECS image id (keeps the AMI latest)
data "aws_ssm_parameter" "bottlerocket_ami" {
  name = "/aws/service/bottlerocket/aws-ecs-1/x86_64/latest/image_id"
}

# Fallback: if SSM param is not available in a region, user can change this block to a specific AMI.
# Launch template using the Bottlerocket image_id
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "${var.name_prefix}-ecs-lt-"
  image_id      = data.aws_ssm_parameter.bottlerocket_ami.value
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ecs_instance_sg_id]
  }

  # Bottlerocket uses simple user-data settings format
  user_data = base64encode(<<-EOF
[settings.ecs]
cluster = "${var.cluster_name != null ? var.cluster_name : "unspecified-cluster"}"
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-ecs-instance" })
  }
}
