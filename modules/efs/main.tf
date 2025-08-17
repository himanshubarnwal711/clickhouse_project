resource "aws_efs_file_system" "this" {
  creation_token = "${var.name_prefix}-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-efs"
  })
}

# Create an access point with posix_user (UID/GID 1000) suitable for ClickHouse
resource "aws_efs_access_point" "ap" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/clickhouse-data"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-efs-ap" })
}

# Mount targets (one per private subnet)
resource "aws_efs_mount_target" "mt" {
  for_each = toset(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.key
  security_groups = [var.efs_security_group_id]
}
