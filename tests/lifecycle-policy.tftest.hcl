# Render lifecycle JSON with the provider, using an offline plan.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

override_data {
  target = data.aws_region.current
  values = { region = "us-east-1" }
}

variables {
  org = {
    organization_name = "Example"
    organization_unit = "Example"
    environment_type  = "development"
    environment_name  = "test"
  }
}

run "policies_for_all_repositories" {
  command = plan

  variables {
    repositories = [
      { name = "omitted-rules" },
      { name = "empty-rules", lifecycle_policy_rules = [] },
    ]
    default_lifecycle_policy = { rules = [] }
  }

  assert {
    condition = alltrue([
      for repo in var.repositories :
      aws_ecr_lifecycle_policy.lifecycle_policy[repo.name].repository == repo.name
    ])
    error_message = "Every repository must have a lifecycle policy."
  }

  assert {
    condition = alltrue([
      for repo in var.repositories :
      one(jsondecode(aws_ecr_lifecycle_policy.lifecycle_policy[repo.name].policy).rules).selection == {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 30
      } && one(jsondecode(aws_ecr_lifecycle_policy.lifecycle_policy[repo.name].policy).rules).action.type == "expire"
    ])
    error_message = "An empty shared policy must fall back to expiring untagged images 30 days after push."
  }
}

run "default_inputs" {
  command = plan

  variables {
    repositories = [{ name = "app" }]
  }

  assert {
    condition = (
      aws_ecr_lifecycle_policy.lifecycle_policy["app"].repository == "app" &&
      one(jsondecode(aws_ecr_lifecycle_policy.lifecycle_policy["app"].policy).rules).selection.countNumber == 30
    )
    error_message = "A repository with only a name must receive the built-in policy."
  }
}

run "custom_policy_precedence" {
  command = plan

  variables {
    repositories = [
      { name = "shared" },
      {
        name = "custom"
        lifecycle_policy_rules = [
          {
            rule_priority = 1
            selection = {
              tag_status       = "tagged"
              tag_pattern_list = ["build-*"]
              count_type       = "imageCountMoreThan"
              count_number     = 10
            }
            action = { type = "expire" }
          },
        ]
      },
    ]
    default_lifecycle_policy = {
      rules = [
        {
          rule_priority = 1
          selection = {
            tag_status   = "untagged"
            count_type   = "sinceImagePushed"
            count_unit   = "days"
            count_number = 60
          }
          action = { type = "expire" }
        },
      ]
    }
  }

  assert {
    condition = alltrue([
      for repo in var.repositories :
      aws_ecr_lifecycle_policy.lifecycle_policy[repo.name].repository == repo.name
    ])
    error_message = "The module must attach each policy to its repository."
  }

  assert {
    condition = (
      one(jsondecode(aws_ecr_lifecycle_policy.lifecycle_policy["shared"].policy).rules).selection.countNumber == 60 &&
      one(jsondecode(aws_ecr_lifecycle_policy.lifecycle_policy["custom"].policy).rules).selection == {
        tagStatus      = "tagged"
        tagPatternList = ["build-*"]
        countType      = "imageCountMoreThan"
        countNumber    = 10
      }
    )
    error_message = "Repository rules must replace shared rules, and repositories with no own rules must inherit the shared policy."
  }
}

run "no_repositories" {
  command = plan

  assert {
    condition     = length(aws_ecr_lifecycle_policy.lifecycle_policy) == 0
    error_message = "The module must create no lifecycle policies when no repositories are configured."
  }
}
