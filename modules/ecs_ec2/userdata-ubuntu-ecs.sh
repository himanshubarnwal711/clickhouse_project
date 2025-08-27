#!/bin/bash
set -xe

# ======== Variables ========
CLUSTER_NAME="${CLUSTER_NAME}" # Pass this value via Terraform or EC2 launch template

# ======== Update system and install prerequisites ========
apt-get update -y
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip

# ======== Install Docker ========
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Enable and Start Docker
systemctl enable docker
systemctl start docker

# ======== Install ECS Agent ========
cd /tmp
curl -O https://s3.ap-south-1.amazonaws.com/amazon-ecs-agent-ap-south-1/amazon-ecs-init-latest.amd64.deb
dpkg -i amazon-ecs-init-latest.amd64.deb

# ======== Configure ECS Cluster ========
mkdir -p /etc/ecs
cat <<EOF > /etc/ecs/ecs.config
ECS_CLUSTER=${CLUSTER_NAME}
ECS_LOGLEVEL=info
ECS_LOGFILE=/var/log/ecs/ecs-agent.log
ECS_DATADIR=/data
EOF

# Enable and start ECS service
systemctl daemon-reload
systemctl enable ecs
systemctl start ecs