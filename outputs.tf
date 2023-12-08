output "id" {
  value       = tfe_workspace.this.id
  description = "The workspace's ID."
}

output "html_url" {
  value       = tfe_workspace.this.html_url
  description = "The URL to the overview page of the workspace."
}

output "terraform_version" {
  value       = tfe_workspace.this.terraform_version
  description = "The version of Terraform used in the workspace."
}

output "name" {
  value       = tfe_workspace.this.name
  description = "Name of the workspace."
}

output "tags" {
  value       = tfe_workspace.this.tag_names
  description = "A list of workspace's tags."
}
