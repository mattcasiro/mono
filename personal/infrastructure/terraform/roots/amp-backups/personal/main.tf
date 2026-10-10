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


module "this" {
  for_each = local.backup_buckets
  source = "../../../modules/aws-s3-amp-backups-bucket"

  name = replace(each.key, "_", "-")
  tags = {
    root        = "amp-backups/personal:${each.key}"
    cost-center = "amp-backups"
  }
}

locals {
  backup_buckets = {
    "amp_icarus_modded" = { import = "true" }
    "amp_palworld" = {import = "true" }
    "amp_soulmask_w_lc" = { import = "true" }
    "amp_vintage_story_friends_r_us" = { import = "true" }
    "valheim_landm_01" = {}
    # "valheim_friends_r_us" = {}
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

import {
  for_each = { for k, v in local.backup_buckets : k => v if try(v.import, false) }

  to       = module.this[each.key].aws_s3_bucket.this
  id       = format("%s-%s-%s-an", replace(each.key, "_", "-"), data.aws_caller_identity.current.account_id, data.aws_region.current.region)
}