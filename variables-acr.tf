##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# repositories: [] # (Optional) Private ECR repositories. Default: [].
#   - name: "app-repository" # (Required) ECR repository name.
#     lifecycle_policy_rules: [] # (Optional) Repository-specific lifecycle rules in the same format as default_lifecycle_policy.rules. Default: [] inherits the shared or built-in policy.
variable "repositories" {
  description = "List of repositories to setup"
  type        = any
  default     = []
}

variable "default_kms_key" {
  description = "Default KMS key to use for encryption"
  type        = string
  default     = ""
}

variable "registry_policy" {
  description = "Registry access policy for the repositories"
  type        = any
  default     = []
}

variable "scanning" {
  description = "Scanning configuration for the repositories"
  type        = any
  default     = {}
}

# default_lifecycle_policy: [] # (Optional) Shared policy. An empty value uses the built-in 30-day untagged image policy.
#   rules: # (Optional) Rules inherited by repositories with no lifecycle_policy_rules.
#     - rule_priority: 1 # (Required) Unique priority within the policy.
#       description: "Expire untagged images 30 days after push" # (Optional) Description. Default: null.
#       selection: # (Required) Select images by tag status and count or age.
#         tag_status: "untagged" # (Required) One of tagged, untagged, or any.
#         tag_prefix_list: [] # (Optional) Tag prefixes for tagged images. Default: omitted.
#         tag_pattern_list: [] # (Optional) Tag patterns for tagged images. Default: omitted.
#         count_type: "sinceImagePushed" # (Required) sinceImagePushed or imageCountMoreThan.
#         count_unit: "days" # (Optional) Defaults to days for sinceImagePushed. Omitted for imageCountMoreThan.
#         count_number: 30 # (Required) Number of days or images.
#       action: # (Required) Action to take on matching images.
#         type: "expire" # (Required) Expire the selected images.
variable "default_lifecycle_policy" {
  description = "Optional shared lifecycle rules. Repositories without custom or shared rules expire untagged images 30 days after push."
  type        = any
  default     = []

  validation {
    condition     = var.default_lifecycle_policy == null || try(length(var.default_lifecycle_policy) == 0, false) || can(var.default_lifecycle_policy.rules)
    error_message = "Supply default_lifecycle_policy as an object with a rules list, or use an empty value for the built-in policy."
  }
}
