provider "tfe" {
  token = "<TFE_TOKEN_HERE>"
}

module "tfe_workspace" {
  source = "../../"

  organization = "my-organization"
  project      = "Default"

  name                        = "InfraTest"
  description                 = "Test environment for infrastructure."
  execution_mode              = "remote"
  apply_method                = "auto"
  terraform_version           = "1.5.5"
  terraform_working_directory = "/terraform/InfraTest"

  tags = ["aws", "test", "infrastructure"]

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
      key   = "TFC_AWS_PROVIDER_AUTH"
      value = true
    },
    {
      key   = "TFC_AWS_RUN_ROLE_ARN"
      value = "arn:aws:iam::123456789012:role/TFE_InfraTest_AccessRole"
    }
  ]

  notifications = [
    {
      name        = "Owners"
      destination = "email"

      recipients = [
        "first.user@my-company.com",
        "secondUser-MyCompany"
      ]

      triggers = [
        "run:created",
        "run:planning",
        "run:needs_attention",
        "run:applying",
        "run:completed",
        "run:errored",
        "assessment:check_failure",
        "assessment:drifted",
        "assessment:failed"
      ]
    },
    {
      name        = "Developers"
      destination = "email"

      recipients = [
        "first.developer@my-company.com",
        "secondDeveloper-MyCompany"
      ]

      triggers = [
        "run:created",
        "run:needs_attention",
        "run:errored"
      ]
    }
  ]

  team_access = [
    {
      team             = "developers"
      permission_group = "custom"
      custom_permission = {
        runs              = "read"
        variables         = "write"
        state_versions    = "read-outputs"
        sentinel_mocks    = "none"
        workspace_locking = false
        run_tasks         = false
      }
    }
  ]
}