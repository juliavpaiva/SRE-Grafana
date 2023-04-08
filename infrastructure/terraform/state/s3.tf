resource "aws_s3_bucket" "bucket-sre-grafana" {
  bucket = var.aws_bucket_name
  aws_s3_bucket_acl    = "private"

  tags = {
    Name        = var.aws_bucket_name
    Environment = var.aws_env
    Repository  = var.aws_repo
  }
}