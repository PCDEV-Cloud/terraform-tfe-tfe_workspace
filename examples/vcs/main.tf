provider "tfe" {
  token = "<TFE-TOKEN-HERE>"
}

data "tfe_project" "default" {
  name         = "Default"
  organization = "<TFE-ORGANIZATION-HERE>"
}

module "tfe_workspace" {
  source = "../../"

  organization = "<TFE-ORGANIZATION-HERE>"
  project_id   = data.tfe_project.default.id

  name                        = "VCS-Example"
  description                 = "VCS example workspace."
  execution_mode              = "remote"
  apply_method                = "auto"
  terraform_version           = "1.5.5"
  terraform_working_directory = "/terraform"

  tags = ["remote"]

  version_control = {
    name                        = "GitHub"
    repository                  = "my-github/my-repository"
    branch                      = "main"
    include_submodules          = true
    automatic_speculative_plans = true

    triggers = {
      type  = "path_patterns"
      paths = ["terraform/**/*"]
    }
  }

  variables = [
    {
      key         = "execution_mode"
      value       = "remote"
      description = "Workspace based on Version Control."
    }
  ]
}