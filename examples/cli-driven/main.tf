provider "tfe" {
  token = "<TFE-TOKEN-HERE>"
}

module "tfe_workspace" {
  source = "../../"

  organization = "<TFE-ORGANIZATION-HERE>"
  project      = "Default"

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