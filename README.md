# ECS EC2 Cluster Deployment with Systemd ECS Agent on Ubuntu

This README provides a step-by-step guide for deploying an **Amazon ECS EC2 Cluster** using **Terraform** with the ECS agent running as a **systemd service** on Ubuntu instances.

---

## ✅ Overview

- **Infrastructure as Code:** Terraform
- **Cluster Type:** ECS EC2 (not Fargate)
- **AMI:** Ubuntu (custom or AWS official)
- **ECS Agent:** Installed and managed via `systemd`
- **Container Runtime:** Docker
- **Launch Template:** Configured with dynamic user data
- **Networking:** VPC, Subnets, Security Groups
- **IAM Role:** ECS Instance Role

---

## 🛠 Prerequisites

1. **Terraform v1.5+**
2. **AWS CLI configured** with proper credentials
3. **Key Pair** for SSH access
4. **IAM Role & Instance Profile** with ECS and SSM permissions
5. **Ubuntu-based AMI** (ensure ECS agent is not pre-installed)

---

## 📂 Directory Structure

```
.
├── modules/
│   ├── ecs_ec2/
│   │   ├── ami_and_launch.tf
│   │   ├── asg_and_capacity.tf
│   │   ├── userdata-ubuntu-ecs.sh
│   │   └── variables.tf
├── main.tf
├── variables.tf
└── outputs.tf
```

---

## 🚀 Key Files

### **ami_and_launch.tf**

Defines the **Launch Template**:

```hcl
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

  user_data = base64encode(templatefile("${path.module}/userdata-ubuntu-ecs.sh", {
    CLUSTER_NAME = var.cluster_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-ecs-instance" })
  }
}
```

---

### **userdata-ubuntu-ecs.sh**

Bootstraps the ECS instance with **Docker** and **ECS Agent (systemd)**:

```bash
#!/bin/bash
set -e

# Variables
CLUSTER_NAME="${CLUSTER_NAME}"

# Update and install dependencies
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker GPG key and repo
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Enable Docker
systemctl enable docker
systemctl start docker

# Create ECS config
mkdir -p /etc/ecs
echo "ECS_CLUSTER=$CLUSTER_NAME" >> /etc/ecs/ecs.config

# Download ECS Agent
docker pull amazon/amazon-ecs-agent:latest

# Create ECS systemd service
cat <<EOF > /etc/systemd/system/ecs-agent.service
[Unit]
Description=Amazon ECS Agent
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --name ecs-agent --rm   -v /var/run/docker.sock:/var/run/docker.sock   -v /var/log/ecs/:/log   -v /var/lib/ecs/data:/data   -p 127.0.0.1:51678:51678   -e ECS_LOGFILE=/log/ecs-agent.log   -e ECS_LOGLEVEL=info   -e ECS_DATADIR=/data   -e ECS_CLUSTER=$CLUSTER_NAME   amazon/amazon-ecs-agent:latest

ExecStop=/usr/bin/docker stop ecs-agent

[Install]
WantedBy=multi-user.target
EOF

# Enable and start ECS Agent
systemctl daemon-reload
systemctl enable ecs-agent
systemctl start ecs-agent
```

---

## ✅ Key Fixes Made

- Corrected Docker APT repository configuration:

```
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" > /etc/apt/sources.list.d/docker.list
```

- ECS Agent now runs as **systemd service** instead of background script.

---

## 🔍 Verification Steps

1. Check ECS agent logs:

```
docker logs ecs-agent
```

2. Confirm instance is registered in ECS:

```
aws ecs list-container-instances --cluster <cluster_name>
```

3. Check systemd service:

```
systemctl status ecs-agent
```

---

## 🧹 Clean Up

To delete the instance profile:

```
aws iam remove-role-from-instance-profile --instance-profile-name <profile_name> --role-name <role_name>
aws iam delete-instance-profile --instance-profile-name <profile_name>
```

---

## 📌 Notes

- Ensure **IAM policies** allow ECS and SSM actions.
- Avoid hardcoding credentials in user data.

---

## ✅ Outputs

- **ECR Repo URL**
- **Docker Image URI**
- **ECS Capacity Provider Name**

```

```
