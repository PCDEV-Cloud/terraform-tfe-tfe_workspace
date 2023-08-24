variable "organization" {
  type        = string
  description = ""
}

variable "project_id" {
  type        = string
  description = ""
}

variable "name" {
  type        = string
  description = ""
}

variable "description" {
  type        = string
  description = ""
}

variable "execution_mode" {
  type        = string
  default     = "remote"
  description = ""

  validation {
    condition     = contains(["remote", "local", "agent"], var.execution_mode)
    error_message = "The object in the \"execution_mode\" must be the \"remote\", \"local\" or \"agent\"."
  }
}

variable "agent_pool_id" {
  type        = string
  default     = null
  description = ""
}

variable "apply_method" {
  type        = string
  default     = "auto"
  description = ""

  validation {
    condition     = contains(["auto", "manual"], var.apply_method)
    error_message = "The object in the \"apply_method\" must be the \"auto\" or \"manual\"."
  }
}

variable "terraform_version" {
  type        = string
  default     = null
  description = ""
}

variable "terraform_working_directory" {
  type        = string
  default     = null
  description = ""
}

variable "tags" {
  type        = list(string)
  default     = []
  description = ""
}

variable "ssh_key" {
  type        = string
  default     = null
  description = ""
}

variable "allow_destroy_plan" {
  type        = bool
  default     = true
  description = ""
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
  description = ""

  validation {
    condition     = contains(["always", "path_prefixes", "path_patterns", "git_tags"], var.version_control["triggers"].type)
    error_message = "The object in the \"triggers.type\" must be the \"always\", \"path_prefixes\", \"path_patterns\" or \"git_tags\"."
  }
  # if type = git_tags then paths = null and regex != null
  # if type = path_prefixes or path_patterns then paths != null and regex = null
  # if type = always then paths = null and regex = null
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
  description = ""
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
  description = ""

  validation {
    condition     = alltrue([for i in var.notifications : i.url != null if contains(["webhook", "slack", "microsoft-teams"], i.destination)])
    error_message = "The \"url\" must be defined if the \"destination\" value is set to \"webhook\", \"slack\" or \"microsoft-teams\"."
  }

  validation {
    condition     = alltrue([for i in var.notifications : i.token != null if i.destination == "webhook"])
    error_message = "The \"token\" must be defined if the \"destination\" value is set to \"webhook\"."
  }

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
  description = ""

  validation {
    condition     = alltrue([for i in var.team_access : contains(["admin", "read", "plan", "write", "custom"], i.permission_group)])
    error_message = "The object in the \"permission_group\" must be the \"admin\", \"read\", \"plan\", \"write\" or \"custom\"."
  }

  validation {
    condition     = alltrue([for i in var.team_access : i.permission_group == "custom" && i.custom_permission != null])
    error_message = "The object in the \"custom_permission\" must be defined if the \"permission_group\" value is set to \"custom\"."
  }
}
