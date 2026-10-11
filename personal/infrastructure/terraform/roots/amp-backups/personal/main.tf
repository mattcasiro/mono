terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }

  backend "s3" {
    bucket       = "mattc-terraform-state"
    key          = "personal/amp-backups/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  backup_buckets = {
    "amp_icarus_modded"              = { import = "true" }
    "amp_palworld"                   = { import = "true" }
    "amp_soulmask_w_lc"              = { import = "true" }
    "amp_vintage_story_friends_r_us" = { import = "true" }
    "amp_valheim_landm_01"           = {}
    "valheim_friends_r_us"           = {}
  }
}

# AMP User
resource "aws_iam_user" "amp_backups_user" {
  name                 = "Amp"
  permissions_boundary = "arn:aws:iam::aws:policy/AmazonS3FullAccess"

  tags = {
    cost-center = "amp-backups"
    root        = "amp-backups/personal"
    terraform   = true
  }
}
import {
  to = aws_iam_user.amp_backups_user
  id = "Amp"
}

data "aws_iam_policy_document" "amp_backups" {
  statement {
    sid     = "s3Buckets"
    actions = ["s3:*"]
    resources = flatten([
      for _, bucket in module.bucket : [
        bucket.bucket_arn,
        "${bucket.bucket_arn}/*",
      ]
    ])
  }
}

resource "aws_iam_user_policy" "amp_backups_user_policy" {
  name   = "AmpS3Access"
  user   = aws_iam_user.amp_backups_user.name
  policy = data.aws_iam_policy_document.amp_backups.json
}
import {
  to = aws_iam_user_policy.amp_backups_user_policy
  id = "Amp:AmpS3Access"
}

# Buckets
moved {
  from = module.this
  to   = module.bucket
}
module "bucket" {
  for_each = local.backup_buckets
  source   = "../../../modules/aws-s3-amp-backups-bucket"

  name = replace(each.key, "_", "-")
  tags = {
    cost-center = "amp-backups"
    root        = "amp-backups/personal:bucket/${each.key}/"
  }
}
import {
  for_each = { for k, v in local.backup_buckets : k => v if try(v.import, false) }

  to = module.bucket[each.key].aws_s3_bucket.this
  id = format("%s-%s-%s-an", replace(each.key, "_", "-"), data.aws_caller_identity.current.account_id, data.aws_region.current.region)
}