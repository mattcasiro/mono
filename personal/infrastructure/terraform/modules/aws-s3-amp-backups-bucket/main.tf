data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_regional_name = format("%s-%s-%s-an", var.name, data.aws_caller_identity.current.account_id, data.aws_region.current.region)
  bucket_name           = var.namespace == "account-regional" ? local.account_regional_name : var.name
}

resource "aws_s3_bucket" "this" {
  bucket           = local.bucket_name
  bucket_namespace = var.namespace

  tags = merge(
    {
      terraform        = "true"
      terraform_module = "aws-s3-amp-backups-bucket"
    },
    var.tags
  )
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}