##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  repos = {
    for repo in var.repositories : repo.name => repo
  }
}
resource "aws_ecr_repository" "this" {
  for_each             = local.repos
  name                 = each.value.name
  force_delete         = try(each.value.force_delete, false)
  image_tag_mutability = try(each.value.image_tag_mutability, "IMMUTABLE")
  encryption_configuration {
    encryption_type = var.default_kms_key != "" ? "KMS" : try(each.value.encryption_type, "AES256")
    kms_key         = try(each.value.kms_key, var.default_kms_key)
  }
  image_scanning_configuration {
    scan_on_push = try(each.value.scan_on_push, false)
  }

  tags = local.all_tags
}

# Inline policies
data "aws_iam_policy_document" "lifecycle_policy" {
  for_each = var.lifecycle_policy
  version  = "2012-10-17"
  dynamic "statement" {
    for_each = each.value.statements
    content {
      sid       = try(statement.value.sid, null)
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "condition" {
        for_each = try(statement.value.conditions, [])
        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

data "aws_iam_policy_document" "repo_policy" {
  for_each = try(local.repos.policy, [])
  version  = "2012-10-17"
  dynamic "statement" {
    for_each = each.value.statements
    content {
      sid       = try(statement.value.sid, null)
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "condition" {
        for_each = try(statement.value.conditions, [])
        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_ecr_repository_policy" "repo_policy" {
  for_each   = local.repos
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.repo_policy.json
}


resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  policy = data.aws_iam_policy_document.lifecycle_policy.json
}

resource "aws_ecr_registry_scanning_configuration" "config" {
  scan_type = try(var.scanning.scan_type, "BASIC")
  dynamic "rule" {
    for_each = var.scanning.rules
    content {
      scan_frequency = try(rule.value.scan_frequency, "SCAN_ON_PUSH")
      repository_filter {
        filter      = try(rule.value.filter, "*")
        filter_type = try(rule.value.filter_type, "WILDCARD")
      }
    }
  }
}