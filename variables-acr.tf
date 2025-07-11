##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

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

variable "default_lifecycle_policy" {
  description = "Default Lifecycle policy for the repositories"
  type        = any
  default     = []
}