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