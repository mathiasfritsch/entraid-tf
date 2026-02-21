variable "app_name" {
  description = "Display name for the Entra ID application"
  type        = string
  default     = "TaxtApp"
}

variable "app_roles" {
  description = "List of app roles to create for the application"
  type = list(object({
    display_name         = string       # Display name shown in Azure Portal
    description          = string       # Description of the role
    value                = string       # Role claim value (used in tokens)
    allowed_member_types = list(string) # ["User"] or ["Application"] or both
  }))

  default = [
    {
      display_name         = "Taxt.Read"
      description          = "Allows read access to Taxt resources"
      value                = "Taxt.Read"
      allowed_member_types = ["User"]
    },
    {
      display_name         = "Taxt.Write"
      description          = "Allows write access to Taxt resources"
      value                = "Taxt.Write"
      allowed_member_types = ["User"]
    }
  ]
}

variable "redirect_uris" {
  description = "List of redirect URIs for web application authentication"
  type        = list(string)
  default     = []

  # Example:
  # default = [
  #   "https://localhost:3000/auth/callback",
  #   "https://myapp.example.com/auth/callback"
  # ]
}

variable "enable_access_token_issuance" {
  description = "Enable access token issuance via implicit flow (not recommended for new apps)"
  type        = bool
  default     = false
}

variable "enable_id_token_issuance" {
  description = "Enable ID token issuance via implicit flow"
  type        = bool
  default     = false
}

variable "enable_api_access" {
  description = "Enable API access configuration for the application"
  type        = bool
  default     = true
}

variable "app_role_assignment_required" {
  description = "Require users to be assigned to app roles before accessing the application"
  type        = bool
  default     = false
}

variable "service_principal_tags" {
  description = "Tags to apply to the service principal"
  type        = list(string)
  default     = ["terraform-managed", "entra-id"]
}

variable "create_client_secret" {
  description = "Create a client secret (password) for the application"
  type        = bool
  default     = false
}

variable "client_secret_end_date" {
  description = "End date for the client secret (ISO 8601 format). Defaults to 2 years from now."
  type        = string
  default     = "2028-02-21T00:00:00Z"
}

variable "required_resource_access" {
  description = "Required API permissions for the application"
  type = list(object({
    resource_app_id = string # Application ID of the API (e.g., Microsoft Graph)
    resource_access = list(object({
      id   = string # Permission ID (UUID)
      type = string # "Scope" for delegated, "Role" for application
    }))
  }))

  default = [
    # Microsoft Graph API - Common permissions
    {
      resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
      resource_access = [
        {
          id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read (delegated)
          type = "Scope"
        }
      ]
    }
  ]
}
