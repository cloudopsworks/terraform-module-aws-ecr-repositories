##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  fallback_lifecycle_rules = [{
    rule_priority = 1
    description   = "Expire untagged images 30 days after push"
    selection = {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 30
    }
    action = { type = "expire" }
  }]
}

data "aws_ecr_lifecycle_policy_document" "lifecycle_policy" {
  for_each = local.repos

  dynamic "rule" {
    for_each = {
      for rule in coalescelist(
        try(each.value.lifecycle_policy_rules[*], []),
        try(var.default_lifecycle_policy.rules[*], []),
        local.fallback_lifecycle_rules,
      ) : rule.rule_priority => rule
    }
    content {
      priority    = rule.value.rule_priority
      description = try(rule.value.description, null)
      selection {
        tag_status       = rule.value.selection.tag_status
        tag_prefix_list  = try(rule.value.selection.tag_prefix_list, null)
        tag_pattern_list = try(rule.value.selection.tag_pattern_list, null)
        count_type       = rule.value.selection.count_type
        count_unit       = rule.value.selection.count_type == "imageCountMoreThan" ? null : coalesce(try(rule.value.selection.count_unit, null), "days")
        count_number     = rule.value.selection.count_number
      }
      action {
        type = rule.value.action.type
      }
    }
  }
}

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  for_each   = local.repos
  repository = aws_ecr_repository.this[each.key].name
  policy     = data.aws_ecr_lifecycle_policy_document.lifecycle_policy[each.key].json
}
