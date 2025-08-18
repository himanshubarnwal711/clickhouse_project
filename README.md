# ECS ClickHouse Deployment on AWS using Terraform

This project provisions an **Amazon ECS Cluster** with EC2 instances running ClickHouse in a private subnet and exposes it via an **Application Load Balancer (ALB)** using **Terraform**.

---

## ✅ Features

- ECS Cluster with EC2 launch type using **Capacity Provider**
- Auto Scaling Group for ECS instances
- ECS Service with desired task count
- ALB with **target group on container port 8123**
- Security Groups for ALB and ECS tasks
- VPC with public and private subnets
- Health checks configured for target group

---

## 🛠 Prerequisites

- **Terraform >= 1.0.0**
- **AWS CLI configured** with proper credentials
- **ECR image** for ClickHouse (already pushed)
- **IAM permissions** for creating VPC, ECS, ALB, EC2, Security Groups, IAM Roles

---

## 📂 Project Structure

```
.
├── main.tf                # Root module
├── variables.tf           # Global variables
├── outputs.tf             # Outputs
├── modules/
│   ├── vpc/               # VPC and subnets
│   ├── ecs_ec2/           # ECS cluster and EC2 instances
│   ├── ecs_service/       # ECS Service and ALB configuration
│   └── security_groups/   # Security groups for ALB and ECS tasks
```

---

## ⚙️ Variables

Important variables:
| Variable | Description |
|----------------------|--------------------------------------------|
| `service_name` | Name of the ECS service |
| `cluster_name` | ECS Cluster name |
| `capacity_provider` | Capacity provider name |
| `private_subnet_ids`| IDs of private subnets for ECS tasks |
| `public_subnet_ids` | IDs of public subnets for ALB |
| `vpc_id` | VPC ID |
| `alb_sg` | Security group for ALB |
| `ecs_task_sg` | Security group for ECS tasks |
| `docker_image_uri` | ECR image URI for ClickHouse |
| `container_name` | Name of the container |
| `container_port` | Container port (8123 for ClickHouse HTTP)|
| `task_cpu` | ECS task CPU |
| `task_memory` | ECS task memory |

---

## 🚀 Deployment Steps

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Validate Configuration

```bash
terraform validate
```

### 3. Plan

```bash
terraform plan -out tfplan
```

### 4. Apply

```bash
terraform apply tfplan
```

### 5. Destroy

```bash
terraform destroy
```

---

## 🔗 ALB & Target Group

- The **ALB** will forward traffic to the ECS service on **container port 8123**.
- Target type is set to **instance**, so the traffic goes to EC2 instances where ECS tasks run.
- Health check path: `/` (can be customized)

---

## ✅ Health Check

Configured with:

- **Path**: `/`
- **Protocol**: HTTP
- **Interval**: 30 seconds
- **Timeout**: 5 seconds
- **Healthy threshold**: 2
- **Unhealthy threshold**: 2

---

## ⚠️ Common Issues & Fixes

- **Error: Specifying both a launch type and capacity provider strategy**  
  Remove `launch_type` when using `capacity_provider_strategy`.

- **Target Group not attaching instances**  
  Ensure the **target_type** is `instance` (not `ip`) for EC2 launch type.

---

## 🖥 Access ClickHouse

Once deployed, the ALB DNS name will provide access to ClickHouse HTTP interface on **port 8123**.

Example:

```
http://<alb-dns-name>:8123/
```

---

### Author

Infrastructure by Terraform | Managed on AWS ECS
