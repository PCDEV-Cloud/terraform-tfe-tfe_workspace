variable "organization" {
  type        = string
  description = "The name of the Terraform Cloud/Enterprise organization."
}

variable "project" {
  type        = string
  description = "The name of the project in which the workspace will be created."
}

variable "name" {
  type        = string
  description = "Name of the workspace."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]+[a-zA-Z0-9]$", var.name))
    error_message = "Name can only contain letters, numbers, hyphens (-) and underscores (_). Must start with a letter and end with a letter or number."
  }

  validation {
    condition     = !can(regex("^.*--.*$", var.name))
    error_message = "Hyphens cannot appear next to each other in a workspace name."
  }

  validation {
    condition     = !can(regex("^.*__.*$", var.name))
    error_message = "Underscores cannot appear next to each other in a workspace name."
  }

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 90
    error_message = "Name must be 3 to 90 characters in length."
  }
}

variable "description" {
  type        = string
  description = "Description of the workspace."
}

variable "execution_mode" {
  type        = string
  default     = "remote"
  description = "Which execution mode to use. Valid values are remote, local and agent for Terraform Cloud and only remote and local for Terraform Enterprise."

  validation {
    condition     = contains(["remote", "local", "agent"], var.execution_mode)
    error_message = "The object in the \"execution_mode\" must be the \"remote\", \"local\" or \"agent\"."
  }
}

variable "agent_pool_id" {
  type        = string
  default     = null
  description = "The ID of an agent pool to assign to the workspace. Required if execution_mode is set to agent."
}

variable "apply_method" {
  type        = string
  default     = "auto"
  description = "Whether to apply changes automatically or manually when a Terraform plan is successful. Valid values are auto and manual."

  validation {
    condition     = contains(["auto", "manual"], var.apply_method)
    error_message = "The object in the \"apply_method\" must be the \"auto\" or \"manual\"."
  }
}

variable "terraform_version" {
  type        = string
  default     = null
  description = "The version of Terraform to use for this workspace."
}

variable "terraform_working_directory" {
  type        = string
  default     = null
  description = "A relative path that Terraform will execute within."
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "A list of tags for this workspace."

  # TODO: lowercase letter, numbers, colons and hyphens
}

variable "ssh_key" {
  type        = string
  default     = null
  description = "The name of an SSH key to assign to the workspace."
}

variable "allow_destroy_plan" {
  type        = bool
  default     = true
  description = "Whether destroy plans can be queued on the workspace."
}

variable "version_control" {
  type = object({
    name                        = string
    repository                  = string
    branch                      = optional(string, "main")
    include_submodules          = optional(bool, false)
    automatic_speculative_plans = optional(bool, true)
    triggers = optional(object({
      type  = string
      paths = optional(list(string))
      regex = optional(string)
      }),
      {
        type  = "always"
        paths = null
        regex = null
      }
    )
  })
  default     = null
  description = "Settings for the workspace's VCS repository."

  validation {
    condition     = var.version_control != null ? contains(["always", "path_prefixes", "path_patterns", "git_tags"], var.version_control["triggers"].type) : true
    error_message = "The object in the \"triggers.type\" must be the \"always\", \"path_prefixes\", \"path_patterns\" or \"git_tags\"."
  }
  # TODO: if type = git_tags then paths = null and regex != null
  # TODO: if type = path_prefixes or path_patterns then paths != null and regex = null
  # TODO: if type = always then paths = null and regex = null
}

variable "variables" {
  type = list(object({
    key         = string
    value       = any
    category    = optional(string, "terraform") # terraform, env
    hcl         = optional(bool, false)
    sensitive   = optional(bool, false)
    description = optional(string, null)
  }))
  default     = []
  description = "A list of variables to be created in the workspace. Valid variable categories are terraform and env."
}

variable "notifications" {
  type = list(object({
    name            = string
    enabled         = optional(bool, true)
    destination     = string # webhook, email, slack, microsoft-teams
    url             = optional(string, null)
    token           = optional(string, null)
    recipients      = optional(list(string), [])
    email_addresses = optional(list(string), []) # only Terraform Enterprise
    triggers        = optional(list(string), []) # run:created, run:planning, run:needs_attention, run:applying, run:completed, run:errored, assessment:check_failure, assessment:drifted, assessment:failed
  }))
  default     = []
  description = "A list of notifications to be created in the workspace. Valid dastinations are webhook, email, slack and microsoft-teams. Note that for Terraform Cloud, the recipients for the email notification should be a list of valid email addresses or usernames added to the organization. For Terraform Enterprise, any email address can be added."

  validation {
    condition     = alltrue([for i in var.notifications : i.url != null if contains(["webhook", "slack", "microsoft-teams"], i.destination)])
    error_message = "The \"url\" must be defined if the \"destination\" value is set to \"webhook\", \"slack\" or \"microsoft-teams\"."
  }

  validation {
    condition     = alltrue([for i in var.notifications : i.token != null if i.destination == "webhook"])
    error_message = "The \"token\" must be defined if the \"destination\" value is set to \"webhook\"."
  }

  # TODO:
  # validation {
  #   condition = alltrue([for i in var.notifications["email_addresses"] : can(regex("^[[:alnum:]]+([+_.-][[:alnum:]]+)*@[0-9a-z]+(.[0-9a-z]+)*(.[[:lower:]]+)$", i))])
  #   error_message = "The \"email_addresses\" values must be valid email addresses, e.g. my-email@my-domain.com."
  # }
}

variable "team_access" {
  type = list(object({
    team             = string
    permission_group = string
    custom_permission = optional(object({
      runs              = string
      variables         = string
      state_versions    = string
      sentinel_mocks    = string
      workspace_locking = bool
      run_tasks         = bool
    }))
  }))
  default     = []
  description = "Associate a team to permissions in the workspace. Valid permission groups are admin, read, plan, write and custom."

  validation {
    condition     = alltrue([for i in var.team_access : contains(["admin", "read", "plan", "write", "custom"], i.permission_group)])
    error_message = "The object in the \"permission_group\" must be the \"admin\", \"read\", \"plan\", \"write\" or \"custom\"."
  }

  validation {
    condition     = alltrue([for i in var.team_access : i.permission_group == "custom" && i.custom_permission != null])
    error_message = "The object in the \"custom_permission\" must be defined if the \"permission_group\" value is set to \"custom\"."
  }
}
