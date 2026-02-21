output "applications" {
  description = "Map of all created applications with their details"
  value = {
    for app_key, app in azuread_application.apps : app_key => {
      application_id        = app.client_id
      application_object_id = app.object_id
      display_name          = app.display_name
      app_roles = {
        for role in app.app_role :
        role.value => {
          id           = role.id
          display_name = role.display_name
          description  = role.description
        }
      }
    }
  }
}

output "service_principals" {
  description = "Map of all created service principals"
  value = {
    for app_key, sp in azuread_service_principal.apps : app_key => {
      service_principal_id        = sp.client_id
      service_principal_object_id = sp.object_id
      display_name                = sp.display_name
    }
  }
}

output "client_secrets" {
  description = "Map of client secrets for applications (only if create_client_secret is true)"
  value = {
    for app_key, secret in azuread_application_password.apps : app_key => {
      key_id = secret.key_id
      value  = secret.value
    }
  }
  sensitive = true
}

output "tenant_id" {
  description = "The tenant ID where the applications are registered"
  value       = data.azuread_client_config.current.tenant_id
}

output "summary" {
  description = "Summary of all created applications"
  value = {
    for app_key, app in azuread_application.apps : app_key => {
      name           = app.display_name
      application_id = app.client_id
      role_count     = length(app.app_role)
      roles          = [for role in app.app_role : role.value]
    }
  }
}
