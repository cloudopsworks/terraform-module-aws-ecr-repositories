##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

data "aws_iam_policy_document" "registry_policy" {
  count   = length(var.registry_policy, []) > 0 ? 1 : 0
  version = "2012-10-17"
  dynamic "statement" {
    for_each = var.registry_policy.statements
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
  policy = data.aws_iam_policy_document.registry_policy[0].json
}
