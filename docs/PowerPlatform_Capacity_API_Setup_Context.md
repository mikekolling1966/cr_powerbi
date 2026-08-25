# Power Platform Capacity API Setup — Context & Progress

## Objective
Build a Power BI report showing Power Platform Dataverse capacity entitlement and consumption using the Power Platform APIs, storing results in a Fabric Lakehouse and connecting to a semantic model.

---

## Architecture
- **Data source**: Power Platform REST APIs
- **Compute**: Microsoft Fabric Notebook (PySpark/Python)
- **Storage**: Fabric Lakehouse (to be confirmed)
- **Reporting**: Power BI semantic model + report

---

## Credentials

| Item | Value |
|---|---|
| Tenant ID | 9a5cacd0-2bef-4dd7-ac5c-7ebe1f54f495 |
| Client ID (App Registration) | 28d48667-10ad-4563-93c3-499438dafbab |
| App Registration Name | Dynamics CRM |
| Client Secret | iUb8Q~v6_N_C41FVhk7kIarErqlH7ulV4FVWCbVq |
| Service Principal Object ID | ce489652-f231-4bf0-884e-f694bcc1a96e |

> ⚠️ The client secret should be moved to Azure Key Vault or Fabric secret store in production.

---

## API Endpoints

### 1. Tenant-level capacity entitlement
```
GET https://api.powerplatform.com/licensing/tenantCapacity?api-version=2024-10-01
Authorization: Bearer <token>
Token audience: https://api.powerplatform.com
```

### 2. Environment-level capacity consumption
```
GET https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments?api-version=2020-10-01&$expand=properties.capacity,properties.addons
Authorization: Bearer <token>
Token audience: https://service.powerapps.com/
```

---

## Authentication (working code)

```python
import requests

tenant_id     = "9a5cacd0-2bef-4dd7-ac5c-7ebe1f54f495"
client_id     = "28d48667-10ad-4563-93c3-499438dafbab"
client_secret = "iUb8Q~v6_N_C41FVhk7kIarErqlH7ulV4FVWCbVq"

# Token for Power Platform API
pp_token_r = requests.post(
    f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token",
    data={
        "client_id":     client_id,
        "client_secret": client_secret,
        "scope":         "https://api.powerplatform.com/.default",
        "grant_type":    "client_credentials"
    }
)
pp_token = pp_token_r.json()["access_token"]

# Token for BAP/PowerApps API
bap_token_r = requests.post(
    f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token",
    data={
        "client_id":     client_id,
        "client_secret": client_secret,
        "scope":         "https://service.powerapps.com/.default",
        "grant_type":    "client_credentials"
    }
)
bap_token = bap_token_r.json()["access_token"]
```

Both tokens return **200** successfully.

---

## Current Status

### ✅ Completed
- App registration `Dynamics CRM` (28d48667-10ad-4563-93c3-499438dafbab) exists in Entra ID
- **Power Platform Administrator** role assigned to service principal (confirmed via Graph API query — role added by Vittoria Pardu, ESAIT, on 09/06/2026)
- **Reports Reader** role also assigned
- Token acquisition working for both `api.powerplatform.com` and `service.powerapps.com` scopes

### ❌ Blocked
- Both API endpoints returning **403 Forbidden**
- Root cause: Service principal has not been **registered with Power Platform** (separate step from Entra role assignment)

---

## Remaining Step — IT Action Required

Microsoft documentation requires a one-time registration of the service principal with Power Platform. This **must be done by a human admin using delegated credentials** — a service principal cannot self-register.

**Reference**: https://learn.microsoft.com/en-us/power-platform/admin/powerplatform-api-create-service-principal

### IT ticket to raise / reply to ticket 226636

Ask Vittoria Pardu (esait.Service.Desk@esa.int) to run the following using their admin PowerShell:

```powershell
# Step 1 - Authenticate
Connect-AzAccount -UseDeviceAuthentication

# Step 2 - Get delegated token
$token = (Get-AzAccessToken -ResourceUrl "https://service.powerapps.com/").Token

# Step 3 - Register the service principal with Power Platform
Invoke-RestMethod `
    -Method PUT `
    -Uri "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/adminApplications/28d48667-10ad-4563-93c3-499438dafbab?api-version=2020-10-01" `
    -Headers @{ Authorization = "Bearer $token" } `
    -ContentType "application/json"
```

Expected response: HTTP 200 or 201 with no error body.

---

## Next Steps (once IT registration is complete)

1. Re-run token acquisition in notebook
2. Test tenant capacity API — expect 200 with JSON payload
3. Test environment capacity API — expect 200 with environment list
4. Build full notebook to:
   - Call both APIs
   - Flatten JSON response into dataframes
   - Save to Fabric Lakehouse as Delta tables:
     - `TenantCapacityEntitlement`
     - `EnvironmentCapacityConsumption`
5. Schedule notebook daily
6. Connect Power BI semantic model to lakehouse tables
7. Build report per PDF spec (section 8):
   - Tenant overview cards
   - Environment ranking bar chart
   - Capacity split stacked bar
   - Percentage of entitlement matrix
   - Trend line chart
   - Governance table

---

## DAX Measures (to add to semantic model once data is loaded)

```dax
Actual Consumption MB = SUM ( EnvironmentCapacityConsumption[ActualConsumptionMB] )
Actual Consumption GB = DIVIDE ( [Actual Consumption MB], 1024 )
Tenant Entitlement MB = SUM ( TenantCapacityEntitlement[TenantEntitlementMB] )
Tenant Entitlement GB = DIVIDE ( [Tenant Entitlement MB], 1024 )
% of Tenant Entitlement = DIVIDE ( [Actual Consumption MB], [Tenant Entitlement MB] )
Environment All-Up Consumption MB = CALCULATE ( [Actual Consumption MB], REMOVEFILTERS ( EnvironmentCapacityConsumption[CapacityType] ) )
Tenant All-Up Entitlement MB = CALCULATE ( [Tenant Entitlement MB], REMOVEFILTERS ( TenantCapacityEntitlement[CapacityType] ) )
Environment All-Up % of Tenant = DIVIDE ( [Environment All-Up Consumption MB], [Tenant All-Up Entitlement MB] )
```

---

## Workspace & Assets

| Item | Location |
|---|---|
| Fabric Workspace | HIF-IA PowerBI Workspace |
| Capacity notebook | Notebook_1 (to be renamed) |
| Target lakehouse | To be confirmed once API access is working |
| IT ticket | Request ID 226636 |

---

*Last updated: 09/06/2026*
