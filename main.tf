module "ecr" {
  source          = "./modules/ecr"
  repository_name = "${local.resource_prefix}-clickhouse"
}

resource "null_resource" "push_docker_image" {
  provisioner "local-exec" {
    command = "./push-image.sh"
  }

  triggers = {
    always_run = timestamp() # forces run every apply
  }
}

data "external" "image_uri" {
  depends_on = [null_resource.push_docker_image]

  program = ["bash", "-c", "echo \"{\\\"image_uri\\\": \\\"$(cat image_uri.txt)\\\"}\""]
}

