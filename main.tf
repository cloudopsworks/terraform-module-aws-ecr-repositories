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

data "aws_ecr_lifecycle_policy_document" "lifecycle_policy" {
  for_each = {
    for k, repo in local.repos : k => repo if length(repo.lifecycle_policy) > 0
  }
  dynamic "rule" {
    for_each = try(repo.lifecycle_policy.rules, [])
    content {
      rule_priority = rule.value.rule_priority
      description   = try(rule.value.description, null)
      selection {
        tag_status       = rule.value.tag_status
        tag_prefix_list  = try(rule.value.tag_prefix_list, null)
        tag_pattern_list = try(rule.value.tag_pattern_list, null)
        count_type       = rule.value.count_type
        count_unit       = try(rule.value.count_unit, "COUNT_NONE")
        count_number     = try(rule.value.count_number, 0)
      }
      action {
        type = rule.value.action.type
      }
    }
  }
}

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  for_each = {
    for k, repo in local.repos : k => repo if length(repo.lifecycle_policy) > 0
  }
  repository = aws_ecr_repository.this.name
  policy     = data.aws_ecr_lifecycle_policy_document.lifecycle_policy[each.key].json
}

data "aws_iam_policy_document" "registry_policy" {
  for_each = var.registry_policy
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

resource "aws_ecr_registry_policy" "registry_policy" {
  count  = length(var.registry_policy) > 0 ? 1 : 0
  policy = data.aws_iam_policy_document.registry_policy.json
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