#!/bin/bash
set -e

# 1. Get the ECR repository URL from Terraform output
ECR_REPO_URL=$(terraform output -raw clickhouse_ecr_repository_url)

# 2. Get AWS account ID and region from the repo URL
AWS_REGION=$(echo $ECR_REPO_URL | cut -d'.' -f4)
IMAGE_TAG="latest"
IMAGE_URI="$ECR_REPO_URL:$IMAGE_TAG"

echo "ECR Repository: $ECR_REPO_URL"
echo "AWS Region: $AWS_REGION"
echo "Image URI: $IMAGE_URI"

# 3. Authenticate Docker to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(echo $ECR_REPO_URL | cut -d'/' -f1)

# 4. Build the Docker image
echo "Building Docker image..."
docker build -t clickhouse-image .

# 5. Tag the image
echo "Tagging image..."
docker tag clickhouse-image:latest $IMAGE_URI

# 6. Push the image to ECR
echo "Pushing image to ECR..."
docker push $IMAGE_URI

# 7. Save Image URI for Terraform
echo $IMAGE_URI > image_uri.txt

# 8. Output final Image URI
echo "✅ Image successfully pushed!"
echo "Image URI: $IMAGE_URI"
