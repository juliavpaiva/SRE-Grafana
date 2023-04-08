variable "aws_region" {
  description = "Deployed region definition"
  default     = "eu-west-1"
}

variable "aws_bucket_name" {
  description = "Application name"
  default     = "bucket-sre-grafana"
}

variable "aws_env" {
  description = "Environment name"
  default     = "dev"
}

variable "aws_repo" {
  description = "Appplication repository"
  default     = "https://github.com/juliavpaiva/SRE-Grafana"
}