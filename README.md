# Entra ID Application Registration with Terraform

This Terraform configuration creates a Microsoft Entra ID (formerly Azure AD) Application Registration with custom App Roles and Service Principal.

## Features

- ✅ Entra ID Application Registration
- ✅ Service Principal creation
- ✅ Custom App Roles for RBAC
- ✅ Configurable API permissions
- ✅ Optional client secret generation
- ✅ Web application redirect URIs support

## Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.0

### Required Permissions
Your Azure account needs the following permissions in Entra ID:
- **Application.ReadWrite.All** - To create and manage applications
- **Directory.Read.All** - To read directory information
- Ideally **Application Administrator** or **Global Administrator** role

### Authentication
This configuration uses Azure CLI authentication:
```powershell
az login
```

Verify you're logged in to the correct tenant:
```powershell
az account show
```

## Quick Start

### 1. Configure Variables
Edit `terraform.tfvars` to customize your application:

```hcl
app_name = "My Application"

app_roles = [
  {
    id                   = "unique-uuid-here"  # Generate with: New-Guid
    display_name         = "Admin"
    description          = "Administrator role"
    value                = "Admin"
    allowed_member_types = ["User"]
  }
]
```

**Important**: Generate unique UUIDs for each app role ID:
```powershell
# PowerShell
New-Guid

# Or use an online UUID generator
```

### 2. Initialize Terraform
```powershell
terraform init
```

This downloads the `azuread` provider.

Or run one command to initialize and create the plan artifacts:
```powershell
.\setup.ps1
```

### 3. Preview Changes
```powershell
terraform plan -out=tfplan
```

Review the resources that will be created.

Optional readable text output:
```powershell
terraform show -no-color tfplan > tfplan.txt
```

### 4. Create Resources
```powershell
terraform apply
```

Type `yes` to confirm.

### 5. View Outputs
```powershell
terraform output
```

Key outputs:
- `application_id` - Client ID for authentication
- `tenant_id` - Your Azure tenant ID
- `app_roles` - Map of role values to role IDs

## Configuration Options

### App Roles

App Roles enable role-based access control (RBAC) within your application. Define them in `terraform.tfvars`:

```hcl
app_roles = [
  {
    id                   = "uuid-1"
    display_name         = "Admin"
    description          = "Full access"
    value                = "Admin"
    allowed_member_types = ["User"]          # User roles
  },
  {
    id                   = "uuid-2"
    display_name         = "Service.Read"
    description          = "Read access for services"
    value                = "Service.Read"
    allowed_member_types = ["Application"]   # Service-to-service roles
  }
]
```

**Member Types:**
- `["User"]` - Can be assigned to users and groups
- `["Application"]` - Can be assigned to service principals (apps)
- `["User", "Application"]` - Can be assigned to both

### Client Secret

To create a client secret (not recommended for production unless needed):

```hcl
create_client_secret = true
client_secret_end_date = "2028-02-21T00:00:00Z"
```

View the secret (only shown once):
```powershell
terraform output client_secret_value
```

### Redirect URIs

For web applications requiring OAuth redirect URIs:

```hcl
redirect_uris = [
  "https://localhost:3000/auth/callback",
  "https://myapp.example.com/auth/callback"
]
```

### API Permissions

Modify `required_resource_access` in `terraform.tfvars` to add Microsoft Graph or other API permissions.

Common Microsoft Graph permission IDs:
- `e1fe6dd8-ba31-4d61-89e7-88639da4683d` - User.Read (delegated)
- `06da0dbc-49e2-44d2-8312-53f166ab848a` - Directory.Read.All (delegated)
- `df021288-bdef-4463-88db-98f22de89214` - User.Read.All (application)

### App Role Assignments Between Applications

Grant one application access to roles defined on another application:

```hcl
app_role_assignments = [
  {
    principal_app = "transactions"
    resource_app  = "documents"
    role_name     = "Documents.Read"
  },
  {
    principal_app = "documents"
    resource_app  = "transactions"
    role_name     = "Transactions.Read"
  }
]
```

This allows the `transactions` app to act with the `Documents.Read` role on the `documents` app, enabling service-to-service communication and delegation of permissions.

**How Terraform Handles Dependencies:**

Role assignments automatically respect the creation order through Terraform's **implicit dependency graph**. When role assignment resources reference attributes from other resources:

```hcl
app_role_id         = azuread_application.apps[...].app_role_ids[...]
principal_object_id = azuread_service_principal.apps[...].object_id
resource_object_id  = azuread_service_principal.apps[...].object_id
```

Terraform detects these attribute references and builds a **DAG (Directed Acyclic Graph)** with explicit edges representing dependencies.

**Concrete Dependency Chain:**

For a typical deployment, the DAG execution order is guaranteed to be:

1. **Random UUIDs** (no dependencies)
   - `random_uuid.app_role_id[...]` creates unique IDs for app roles

2. **Applications** (depend on Random UUIDs)
   - `azuread_application.apps["documents"]` uses `random_uuid.app_role_id[...]` for role IDs
   - `azuread_application.apps["transactions"]` uses `random_uuid.app_role_id[...]` for role IDs

3. **Service Principals** (depend on Applications)
   - `azuread_service_principal.apps["documents"]` references `azuread_application.apps["documents"].client_id`
   - `azuread_service_principal.apps["transactions"]` references `azuread_application.apps["transactions"].client_id`

4. **App Role Assignments** (depend on Applications AND Service Principals)
   - `azuread_app_role_assignment.assignments[...]` references:
     - `azuread_application.apps[...].app_role_ids[...]` ← requires step 2
     - `azuread_service_principal.apps[...].object_id` ← requires step 3

This sequential ordering is **guaranteed by Terraform's engine** without race conditions because:
- Each resource waits for all of its dependencies to complete
- Terraform respects the DAG when determining parallelization
- Resources with independent dependencies (e.g., two different applications) can still execute in parallel

No explicit `depends_on` is needed—the attribute references automatically encode all dependencies.

## Usage

### Assigning App Roles to Users

**Via Azure Portal:**
1. Navigate to **Entra ID** > **Enterprise Applications**
2. Find your application
3. Go to **Users and groups** > **Add user/group**
4. Select user and assign a role

**Via Terraform:**
Create an additional resource in your configuration:

```hcl
resource "azuread_app_role_assignment" "example" {
  app_role_id         = azuread_application.main.app_role[0].id
  principal_object_id = "<user-object-id>"
  resource_object_id  = azuread_service_principal.main.object_id
}
```

### Viewing in Azure Portal

After running `terraform apply`:
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Entra ID** > **App registrations**
3. Find your application by name
4. View **App roles** to see custom roles
5. Check **API permissions** for granted permissions

### Granting Admin Consent

If you added application permissions (type = "Role"), grant admin consent:

**Via Azure CLI:**
```powershell
az ad app permission admin-consent --id <application-id>
```

**Via Azure Portal:**
1. Go to your app registration
2. Navigate to **API permissions**
3. Click **Grant admin consent for [Tenant Name]**

## Verification

### Check Application via Azure CLI
```powershell
# List your applications
az ad app list --display-name "My Application"

# View app roles
az ad app show --id <application-id> --query appRoles
```

### Check Service Principal
```powershell
az ad sp show --id <application-id>
```

### Test Authentication
Use the output `application_id` and `tenant_id` to configure your application for authentication.

## Cleanup

To remove all resources:
```powershell
terraform destroy
```

Type `yes` to confirm deletion.

## State Management

Currently using local state file (`terraform.tfstate`). 

**⚠️ Warning:** This file contains sensitive information including client secrets. Never commit it to version control!

Add to `.gitignore`:
```
*.tfstate
*.tfstate.*
.terraform/
```

### Migrating to Remote State (Recommended for Production)

Use Azure Storage backend:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateXXXXX"
    container_name       = "tfstate"
    key                  = "entraid-app.tfstate"
  }
}
```

## Troubleshooting

### "Insufficient privileges to complete the operation"
- Ensure you have **Application.ReadWrite.All** permission
- Your account may need **Application Administrator** role

### "The value of parameter app.appRoles is invalid"
- Ensure all role IDs are unique UUIDs
- Check that `allowed_member_types` is either `["User"]`, `["Application"]`, or both

### "The client secret has expired"
- Update `client_secret_end_date` to a future date
- Run `terraform apply` to rotate the secret

### "Invalid redirect URI"
- Ensure URIs use HTTPS (except localhost)
- URIs must not contain fragments (#)
- URIs must not contain wildcards (*)

## Security Best Practices

1. **Never commit secrets**: Keep `terraform.tfstate` out of version control
2. **Use remote state**: Store state securely in Azure Storage with encryption
3. **Rotate secrets regularly**: Set appropriate `client_secret_end_date`
4. **Principle of least privilege**: Only grant necessary API permissions
5. **Enable app role assignment**: Set `app_role_assignment_required = true` to require explicit role assignment
6. **Review permissions regularly**: Audit app roles and API permissions

## Additional Resources

- [Terraform AzureAD Provider Documentation](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
- [Microsoft Entra ID Documentation](https://learn.microsoft.com/en-us/entra/identity/)
- [App Roles Documentation](https://learn.microsoft.com/en-us/entra/identity-platform/howto-add-app-roles-in-apps)
- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)

## License

This configuration is provided as-is for educational and development purposes.
