#!/bin/bash
set -xe

# ======== Variables ========
CLUSTER_NAME="${CLUSTER_NAME}" # Pass this value via Terraform or EC2 launch template

# ======== Update system and install prerequisites ========
sudo yum update -y
sudo dnf install -y curl unzip jq tar shadow-utils --skip-broken

# ======== Install Docker (Amazon Linux 2023 uses dnf plugins) ========
sudo yum install -y docker
sudo service docker start

# Add ec2-user to docker group
sudo usermod -aG docker ec2-user


# Enable and Start Docker
sudo systemctl enable --now docker

# ======== Install ECS Agent from S3 ========
curl -O https://s3.ap-south-1.amazonaws.com/amazon-ecs-agent-ap-south-1/amazon-ecs-init-latest.x86_64.rpm
sudo yum localinstall -y amazon-ecs-init-latest.x86_64.rpm

# ======== Configure ECS Cluster ========
mkdir -p /etc/ecs
sudo sh -c "cat <<EOF > /etc/ecs/ecs.config
ECS_CLUSTER=${CLUSTER_NAME}
ECS_LOGLEVEL=info
ECS_LOGFILE=/var/log/ecs/ecs-agent.log
ECS_DATADIR=/data
EOF"

# Enable and Start ECS Agent
sudo systemctl enable --now ecs
