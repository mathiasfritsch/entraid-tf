terraform {
  required_version = ">= 1.0"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

provider "azuread" {
  # Authentication via Azure CLI (az login)
  # Ensure you have logged in with: az login
}

# Data source to get current client configuration
data "azuread_client_config" "current" {}

# Generate random UUIDs for app role IDs
resource "random_uuid" "app_role_id" {
  for_each = { for idx, role in var.app_roles : idx => role }
}

# Create the Entra ID Application
resource "azuread_application" "main" {
  display_name = var.app_name
  owners       = [data.azuread_client_config.current.object_id]

  # App roles for role-based access control
  dynamic "app_role" {
    for_each = var.app_roles
    content {
      allowed_member_types = app_role.value.allowed_member_types
      description          = app_role.value.description
      display_name         = app_role.value.display_name
      enabled              = true
      id                   = random_uuid.app_role_id[app_role.key].result
      value                = app_role.value.value
    }
  }

  # Web application configuration (optional)
  dynamic "web" {
    for_each = length(var.redirect_uris) > 0 ? [1] : []
    content {
      redirect_uris = var.redirect_uris

      implicit_grant {
        access_token_issuance_enabled = var.enable_access_token_issuance
        id_token_issuance_enabled     = var.enable_id_token_issuance
      }
    }
  }

  # API configuration
  dynamic "api" {
    for_each = var.enable_api_access ? [1] : []
    content {
      mapped_claims_enabled          = false
      requested_access_token_version = 2
    }
  }

  # Required API permissions (Microsoft Graph by default)
  dynamic "required_resource_access" {
    for_each = var.required_resource_access
    content {
      resource_app_id = required_resource_access.value.resource_app_id

      dynamic "resource_access" {
        for_each = required_resource_access.value.resource_access
        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }
}

# Create Service Principal for the application
resource "azuread_service_principal" "main" {
  client_id                    = azuread_application.main.client_id
  app_role_assignment_required = var.app_role_assignment_required
  owners                       = [data.azuread_client_config.current.object_id]

  tags = var.service_principal_tags
}

# Optional: Create application password (client secret)
resource "azuread_application_password" "main" {
  count = var.create_client_secret ? 1 : 0

  application_id = azuread_application.main.id
  display_name   = "Terraform-managed secret"
  end_date       = var.client_secret_end_date
}
