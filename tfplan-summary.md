# Terraform Plan Summary - TaxtApp

**Generated:** February 21, 2026  
**Tenant ID:** b925eae5-3023-4f8d-8414-8c56b7cee858

## Overview
This plan will create **4 new resources** for an Entra ID application registration with custom app roles.

## Resources to Create

### 1. Entra ID Application: `TaxtApp`
**Resource:** `azuread_application.main`

| Property | Value |
|----------|-------|
| Display Name | TaxtApp |
| Sign-in Audience | AzureADMyOrg (single tenant) |
| API Token Version | 2 |
| Mapped Claims | Disabled |

#### App Roles (2)
1. **Taxt.Read**
   - Description: Allows read access to Taxt resources
   - Allowed Members: User
   - Status: Enabled
   - Value: `Taxt.Read`
   - ID: Auto-generated

2. **Taxt.Write**
   - Description: Allows write access to Taxt resources
   - Allowed Members: User
   - Status: Enabled
   - Value: `Taxt.Write`
   - ID: Auto-generated

#### API Permissions
- **Microsoft Graph API** (00000003-0000-0000-c000-000000000000)
  - User.Read (e1fe6dd8-ba31-4d61-89e7-88639da4683d) - Delegated/Scope

### 2. Service Principal
**Resource:** `azuread_service_principal.main`

| Property | Value |
|----------|-------|
| Account Enabled | Yes |
| App Role Assignment Required | No |
| Tags | `entra-id`, `terraform-managed` |

### 3. Random UUIDs (2)
**Resources:** `random_uuid.app_role_id["0"]` and `random_uuid.app_role_id["1"]`

Two unique identifiers will be generated for the app role IDs.

## Outputs After Apply

The following values will be available after successful deployment:

| Output | Description |
|--------|-------------|
| `application_id` | Client ID for authentication |
| `application_name` | "TaxtApp" |
| `application_object_id` | Internal object ID |
| `service_principal_id` | Service principal client ID |
| `service_principal_object_id` | Service principal object ID |
| `tenant_id` | b925eae5-3023-4f8d-8414-8c56b7cee858 |
| `app_roles` | Map of role names to their IDs |
| `app_role_ids` | List of all role IDs |
| `app_role_details` | Complete role information |

## Summary Statistics

- **Total Resources:** 4
- **Resources to Add:** 4
- **Resources to Change:** 0
- **Resources to Destroy:** 0

## Next Steps

To apply this plan:
```powershell
terraform apply "tfplan"
```

To cancel and review:
```powershell
# Delete the plan file
rm tfplan
# Make changes and re-run
terraform plan -out=tfplan
```

## Security Notes

- App role assignment is **not required** - any user in the tenant can access the app by default
- Consider setting `app_role_assignment_required = true` to enforce role-based access
- No client secrets are created in this plan
- Microsoft Graph User.Read permission requires user consent or admin consent
