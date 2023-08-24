data "tfe_organization" "this" {
  name = var.organization
}

################################################################################
# Workspace
################################################################################

data "tfe_oauth_client" "this" {
  count = var.version_control != null ? 1 : 0

  organization = data.tfe_organization.this.name
  name         = var.version_control["name"]
}

data "tfe_ssh_key" "this" {
  count = var.ssh_key != null ? 1 : 0

  organization = data.tfe_organization.this.name
  name         = var.ssh_key
}

resource "tfe_workspace" "this" {
  organization       = data.tfe_organization.this.name
  project_id         = var.project_id
  name               = var.name
  description        = var.description
  execution_mode     = var.execution_mode
  agent_pool_id      = var.execution_mode == "agent" ? var.agent_pool_id : null
  auto_apply         = var.apply_method == "auto" ? true : false
  terraform_version  = var.terraform_version
  working_directory  = var.terraform_working_directory
  tag_names          = var.tags
  ssh_key_id         = try(data.tfe_ssh_key.this[0].id, null)
  allow_destroy_plan = var.allow_destroy_plan

  dynamic "vcs_repo" {
    for_each = var.version_control != null ? [1] : []
    content {
      oauth_token_id     = data.tfe_oauth_client.this[0].oauth_token_id
      identifier         = var.version_control["repository"]
      branch             = var.version_control["branch"]
      ingress_submodules = var.version_control["include_submodules"]
      tags_regex         = var.version_control["triggers"].type == "git_tags" ? var.version_control["triggers"].regex : null
      # github_app_installation_id = ""
    }
  }

  speculative_enabled   = var.version_control["automatic_speculative_plans"]
  queue_all_runs        = var.version_control["triggers"].type == "always" ? true : false
  trigger_patterns      = var.version_control["triggers"].type == "path_patterns" ? var.version_control["triggers"].paths : null
  trigger_prefixes      = var.version_control["triggers"].type == "path_prefixes" ? var.version_control["triggers"].paths : null
  file_triggers_enabled = contains(["path_patterns", "path_prefixes"], var.version_control["triggers"].type) ? true : false
  # tags_regex          = var.version_control["triggers"].type == "git_tags" ? var.version_control["triggers"].values : null
}

################################################################################
# Variables
################################################################################

locals {
  variables = { for i, k in var.variables : k.key => k }
}

resource "tfe_variable" "this" {
  for_each = local.variables

  workspace_id = tfe_workspace.this.id
  key          = each.value["key"]
  value        = each.value["value"]
  category     = each.value["category"]
  hcl          = each.value["hcl"]
  sensitive    = each.value["sensitive"]
  description  = each.value["description"]
}

################################################################################
# Notifications
################################################################################

data "tfe_organization_membership" "by_email" {
  for_each = local.recipients_by_email

  organization = data.tfe_organization.this.name
  email        = each.key
}

data "tfe_organization_membership" "by_username" {
  for_each = local.recipients_by_username

  organization = data.tfe_organization.this.name
  username     = each.key
}

locals {
  recipients_by_email    = toset(distinct(flatten([for i in var.notifications : [for j in i.recipients : j if can(regex("^[[:alnum:]]+([+_.-][[:alnum:]]+)*@[0-9a-z]+(.[0-9a-z]+)*(.[[:lower:]]+)$", j))]])))
  recipients_by_username = toset(distinct(flatten([for i in var.notifications : [for j in i.recipients : j if !can(regex("^[[:alnum:]]+([+_.-][[:alnum:]]+)*@[0-9a-z]+(.[0-9a-z]+)*(.[[:lower:]]+)$", j))]])))

  all_recipients = merge(
    { for i, k in data.tfe_organization_membership.by_email : i => k.user_id },
    { for i, k in data.tfe_organization_membership.by_username : i => k.user_id }
  )

  webhook_notifications         = { for i, k in var.notifications : k.name => k if k.destination == "webhook" }
  email_notifications           = { for i, k in var.notifications : k.name => k if k.destination == "email" }
  slack_notifications           = { for i, k in var.notifications : k.name => k if k.destination == "slack" }
  microsoft_teams_notifications = { for i, k in var.notifications : k.name => k if k.destination == "microsoft-teams" }
}

resource "tfe_notification_configuration" "webhook" {
  for_each = local.webhook_notifications

  workspace_id     = tfe_workspace.this.id
  name             = each.value["name"]
  enabled          = each.value["enabled"]
  destination_type = "generic"
  url              = each.value["url"]
  token            = each.value["token"]
  triggers         = each.value["triggers"]
}

resource "tfe_notification_configuration" "email" {
  for_each = local.email_notifications

  workspace_id     = tfe_workspace.this.id
  name             = each.value["name"]
  enabled          = each.value["enabled"]
  destination_type = "email"
  email_user_ids   = [for i in each.value["recipients"] : local.all_recipients[i]]
  email_addresses  = each.value["email_addresses"] # only Terraform Enterprise
  triggers         = each.value["triggers"]
}

resource "tfe_notification_configuration" "slack" {
  for_each = local.slack_notifications

  workspace_id     = tfe_workspace.this.id
  name             = each.value["name"]
  enabled          = each.value["enabled"]
  destination_type = "slack"
  url              = each.value["url"]
  triggers         = each.value["triggers"]
}

resource "tfe_notification_configuration" "microsoft_teams" {
  for_each = local.microsoft_teams_notifications

  workspace_id     = tfe_workspace.this.id
  name             = each.value["name"]
  enabled          = each.value["enabled"]
  destination_type = "microsoft-teams"
  url              = each.value["url"]
  triggers         = each.value["triggers"]
}

################################################################################
# Team Access
################################################################################

data "tfe_team" "this" {
  for_each = local.team_access

  organization = data.tfe_organization.this.name
  name         = each.value["team"]
}

locals {
  team_access = { for i, k in var.team_access : k.team => k }
}

resource "tfe_team_access" "this" {
  for_each = local.team_access

  workspace_id = tfe_workspace.this.id
  team_id      = data.tfe_team.this[each.key].id
  access       = each.value["permission_group"] != "custom" ? each.value["permission_group"] : null

  dynamic "permissions" {
    for_each = each.value["permission_group"] == "custom" ? [1] : []
    content {
      runs              = each.value["custom_permission"].runs
      variables         = each.value["custom_permission"].variables
      state_versions    = each.value["custom_permission"].state_versions
      sentinel_mocks    = each.value["custom_permission"].sentinel_mocks
      workspace_locking = each.value["custom_permission"].workspace_locking
      run_tasks         = each.value["custom_permission"].run_tasks
    }
  }
}
