output "id" {
  value       = tfe_workspace.this.id
  description = "The workspace ID."
}

output "html_url" {
  value       = tfe_workspace.this.html_url
  description = "The URL to the overview page of the workspace."
}