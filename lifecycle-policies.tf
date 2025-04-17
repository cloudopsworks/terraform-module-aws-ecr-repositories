##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

data "aws_ecr_lifecycle_policy_document" "default_lifecycle_policy" {
  count = length(var.default_lifecycle_policy, []) > 0 ? 1 : 0
  dynamic "rule" {
    for_each = {
      for rule in try(var.default_lifecycle_policy.rules, []) : "default-${rule.rule_priority}" => rule
    }
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

data "aws_ecr_lifecycle_policy_document" "lifecycle_policy" {
  for_each = {
    for k, repo in local.repos : k => repo if length(try(repo.lifecycle_policy_rules, [])) > 0
  }
  dynamic "rule" {
    for_each = {
      for rule in try(each.value.lifecycle_policy_rules, []) : "${each.k}-${rule.rule_priority}" => rule
    }
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
    for k, repo in local.repos : k => repo if length(try(repo.lifecycle_policy_rules, [])) > 0 || length(var.default_lifecycle_policy) > 0
  }
  repository = aws_ecr_repository.this[each.key].name
  policy     = try(data.aws_ecr_lifecycle_policy_document.lifecycle_policy[each.key].json, data.aws_ecr_lifecycle_policy_document.default_lifecycle_policy[0].json)
}
