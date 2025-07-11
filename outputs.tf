##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#
output "repositories" {
  description = "Information of the created repositories"
  value = {
    for repo in aws_ecr_repository.this : repo.name => {
      arn         = repo.arn
      registry_id = repo.registry_id
    }
  }
}