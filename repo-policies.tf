##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Inline policies
data "aws_iam_policy_document" "repo_policy" {
  for_each = {
    for k, repo in local.repos : k => repo if length(try(repo.policy.statements, [])) > 0
  }
  version = "2012-10-17"
  dynamic "statement" {
    for_each = each.value.policy.statements
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
  for_each = {
    for k, repo in local.repos : k => repo if length(try(repo.policy.statements, [])) > 0
  }
  repository = aws_ecr_repository.this[each.key].name
  policy     = data.aws_iam_policy_document.repo_policy[each.key].json
}
