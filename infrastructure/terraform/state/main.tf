provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "SRE-GRAFANA"
      ManagedBy = "Terraform"
      Owner     = "Julia Paiva"
    }
  }
}