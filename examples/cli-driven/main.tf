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

  name                        = "CLI-Driven-Example"
  description                 = "CLI-Driven example workspace."
  execution_mode              = "local"
  apply_method                = "auto"
  terraform_version           = "1.5.5"
  terraform_working_directory = "/terraform"

  tags = ["local"]

  variables = [
    {
      key         = "execution_mode"
      value       = "local"
      description = "CLI-Driven workspace."
    }
  ]
}