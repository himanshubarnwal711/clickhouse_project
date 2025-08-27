resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "${var.name_prefix}-ecs-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ecs_instance_sg_id]
  }

  # Ubuntu ECS bootstrap script
  user_data = base64encode(templatefile("${path.module}/userdata-ubuntu-ecs.sh", {
    CLUSTER_NAME = var.cluster_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-ecs-instance" })
  }
}
