# Terraform Cloud/Enterprise Workspace module

## Features
1. Create a Terraform Cloud/Enterprise workspace.
2. Connect the workspace to version control provider.
3. Configure workspace variables.
4. Create workspace notifications.
5. Manage team access to the workspace.

> [!WARNING]
>
> In version `v1.3.0`, the `var.project` variable has been replaced with the `var.project_id`.
> Before updating the module, replace the `project` argument with `project_id` with the project's ID instead of project's name as a value.

> [!WARNING]
> 
> Terraform Enterprise-only features have not been tested.

> [!NOTE]
>
> Support for Run Tasks, Run Triggers and Policies in progress.

## Usage

```hcl
module "tfe_workspace" {
  source = "github.com/PCDEV-Cloud/terraform-tfe-tfe_workspace"

  organization = "my-organization"
  project_id   = "my-project-id"

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
```

## Examples

- [vcs](https://github.com/PCDEV-Cloud/terraform-tfe-tfe_workspace/tree/main/examples/vcs-driven) - Creates a workspace based on Version Control
- [cli-driven](https://github.com/PCDEV-Cloud/terraform-tfe-tfe_workspace/tree/main/examples/cli-driven) - Creates a CLI-Driven workspace
