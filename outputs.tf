output "application_id" {
  description = "The Application (Client) ID of the Entra ID application"
  value       = azuread_application.main.client_id
}

output "application_object_id" {
  description = "The Object ID of the Entra ID application"
  value       = azuread_application.main.object_id
}

output "application_name" {
  description = "The display name of the Entra ID application"
  value       = azuread_application.main.display_name
}

output "service_principal_id" {
  description = "The Application ID of the service principal (same as application_id)"
  value       = azuread_service_principal.main.client_id
}

output "service_principal_object_id" {
  description = "The Object ID of the service principal"
  value       = azuread_service_principal.main.object_id
}

output "app_roles" {
  description = "Map of app role values to their IDs"
  value = {
    for role in azuread_application.main.app_role :
    role.value => role.id
  }
}

output "app_role_ids" {
  description = "List of app role IDs"
  value       = [for role in azuread_application.main.app_role : role.id]
}

output "app_role_details" {
  description = "Detailed information about each app role"
  value = [
    for role in azuread_application.main.app_role : {
      id                   = role.id
      display_name         = role.display_name
      value                = role.value
      description          = role.description
      allowed_member_types = role.allowed_member_types
    }
  ]
}

output "client_secret_value" {
  description = "The client secret value (only available if create_client_secret is true)"
  value       = var.create_client_secret ? azuread_application_password.main[0].value : null
  sensitive   = true
}

output "client_secret_key_id" {
  description = "The key ID of the client secret"
  value       = var.create_client_secret ? azuread_application_password.main[0].key_id : null
}

output "tenant_id" {
  description = "The tenant ID where the application is registered"
  value       = data.azuread_client_config.current.tenant_id
}
