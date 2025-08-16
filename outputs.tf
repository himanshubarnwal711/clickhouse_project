output "clickhouse_ecr_repository_url" {
  description = "ECR repository URL for ClickHouse image"
  value       = module.ecr.repository_url
}

output "docker_image_uri" {
  value       = data.external.image_uri.result["image_uri"]
  description = "The full URI of the pushed Docker image"
}
