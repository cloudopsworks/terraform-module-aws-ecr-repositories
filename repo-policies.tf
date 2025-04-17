##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

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
