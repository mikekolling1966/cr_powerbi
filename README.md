# CRM Infrastructure Monitoring

> Automated daily health metrics collection from ESA D365 CRM (Dataverse) environments, stored in Microsoft Fabric and visualised in Power BI.

---

## Overview

This solution collects key infrastructure health metrics from the ESA D365 CRM production and development environments on a daily schedule. Data is written to a Delta table in Microsoft Fabric and surfaced in the Power BI dashboard as the **Infrastructure Health** page.

### What It Monitors

| Metric | Source | Alert Threshold |
|---|---|---|
| Failed system jobs | Dataverse asyncoperations | > 100 |
| Active users vs licence limit | RetrieveOrganizationResources | — |
| Custom entities vs max | RetrieveOrganizationResources | — |
| Enabled system users | Dataverse systemusers | — |
| Plugin crashes | plugintypestatistics | — |
| DB / File / Log storage | ⚠️ Pending permissions | TBD |

---

## Architecture

```
Dataverse API (DEV + PROD)
        │
        ▼
Fabric Notebook (daily 06:00 UTC)
        │
        ▼
CRM_Monitoring Lakehouse
└── crm_health_snapshot (Delta table)
        │
        ▼
Semantic Model (Direct Lake)
        │
        ▼
Power BI Report → Infrastructure Health page
```

---

## Repository Structure

```
├── notebooks/
│   ├── DEV_Capacity_Notebook.ipynb     # Pulls from esacontact-dev environment
│   └── PROD_Capacity_Notebook.ipynb    # Pulls from esacontact (production)
├── theme/
│   └── CRM_Dark_Navy_Theme_V2.json     # Power BI theme file
├── docs/
│   └── CRM_Infrastructure_Monitoring_Solution.docx
└── README.md
```

---

## Notebooks

### Cell Structure

Both notebooks share the same structure. Only **Cell 2** differs between DEV and PROD.

| Cell | Purpose |
|---|---|
| 1 | `%pip install msal requests pandas` — run this cell **alone first**, then Run All |
| 2 | Configuration — TENANT_ID, CLIENT_ID, CLIENT_SECRET, DATAVERSE_URL, ENVIRONMENT_ID |
| 3 | Authenticate via MSAL (Service Principal client credentials) |
| 4 | Fetch org resources — active users, custom entities, storage limits |
| 5 | Fetch failed system jobs count |
| 6 | Fetch enabled users count |
| 7 | Fetch plugin execution / crash stats |
| 8 | Build pandas DataFrame with `environment` column |
| 9 | Write to Delta table via PySpark `saveAsTable` with `mergeSchema=true` |
| 10 | Verify — SELECT from table to confirm write |

### Running Locally / Manually

> ⚠️ Due to the pip install cell triggering a kernel restart, always run in two steps:

1. Run **Cell 1 only** and wait for kernel restart
2. Click **Run All** for remaining cells

### Schedule

Both notebooks are scheduled via Fabric notebook scheduler:

- **Frequency:** Daily
- **Time:** 06:00 UTC
- **Output:** 1 row appended to `crm_health_snapshot` per run

---

## Configuration

### DEV Notebook — Cell 2

```python
TENANT_ID      = '9a5cacd0-2bef-4dd7-ac5c-7ebe1f54f495'
CLIENT_ID      = '28d48667-10ad-4563-93c3-499438dafbab'
CLIENT_SECRET  = '<secret>'                                    # See secret management below
DATAVERSE_URL  = 'https://esacontact-dev.crm4.dynamics.com'
ENVIRONMENT_ID = '0e65fbbb-7553-4a35-970e-0c65b99136d5'
environment    = 'DEV'
```

### PROD Notebook — Cell 2

```python
TENANT_ID      = '9a5cacd0-2bef-4dd7-ac5c-7ebe1f54f495'
CLIENT_ID      = '28d48667-10ad-4563-93c3-499438dafbab'
CLIENT_SECRET  = '<secret>'                                    # See secret management below
DATAVERSE_URL  = 'https://esacontact.crm4.dynamics.com'
ENVIRONMENT_ID = '2c31dc4f-f142-4c34-b691-e24228103ea2'
environment    = 'PROD'
```

> ⚠️ **Never commit the actual CLIENT_SECRET value to GitLab.** Replace with `<secret>` in committed files and store the real value securely.

---

## Data — crm_health_snapshot

**Location:** CRM_Monitoring Lakehouse → Tables → crm_health_snapshot  
**Format:** Delta table, append mode  
**Growth rate:** 2 rows/day (1 DEV + 1 PROD)

### Schema

| Column | Type | Description |
|---|---|---|
| `environment` | string | `DEV` or `PROD` |
| `snapshot_date` | timestamp | UTC timestamp of collection |
| `active_users_current` | long | Current active licensed users |
| `active_users_max` | long | Max licensed users (200,000) |
| `active_users_pct` | double | Licence capacity used % |
| `non_interactive_users_current` | long | Non-interactive users in use |
| `non_interactive_users_max` | long | Non-interactive user limit (7) |
| `custom_entities_current` | long | Custom Dataverse tables created |
| `custom_entities_max` | long | Max custom tables (3,000) |
| `custom_entities_pct` | double | Custom entity limit used % |
| `published_workflows_current` | long | Published workflows count |
| `published_workflows_max` | long | Max published workflows |
| `max_storage_bytes` | long | Total storage allocation in bytes |
| `max_storage_gb` | double | Total storage allocation in GB |
| `current_storage_bytes` | long | Current storage used (pending permissions) |
| `failed_system_jobs` | long | Failed background system jobs |
| `enabled_users` | long | Enabled system users (OData cap: 5,000) |
| `plugin_total_executions` | long | Total plugin executions |
| `plugin_total_crashes` | long | Total plugin crashes |
| `db_storage_used_mb` | void | ⚠️ Pending — requires Power Platform Admin role |
| `file_storage_used_mb` | void | ⚠️ Pending — requires Power Platform Admin role |
| `log_storage_used_mb` | void | ⚠️ Pending — requires Power Platform Admin role |
| `storage_pending_permissions` | boolean | `true` while storage data unavailable |

---

## Authentication

Authentication uses a **Service Principal** (App Registration) with MSAL client credentials flow.

| Item | Value |
|---|---|
| App Registration | Dynamics CRM |
| Application ID | `28d48667-10ad-4563-93c3-499438dafbab` |
| Tenant ID | `9a5cacd0-2bef-4dd7-ac5c-7ebe1f54f495` |
| Dataverse scope | `https://esacontact-dev.crm4.dynamics.com/.default` |
| Dataverse role (DEV) | System Administrator on esacontact-dev |
| Dataverse role (PROD) | System Administrator on esacontact |

### API Endpoints Called

```
GET /api/data/v9.2/RetrieveOrganizationResources
GET /api/data/v9.2/asyncoperations?$filter=statecode eq 3 and statuscode eq 31&$count=true
GET /api/data/v9.2/systemusers?$filter=isdisabled eq false&$count=true
GET /api/data/v9.2/plugintypestatistics
```

---

## Power BI

### Report
- **Name:** V4PROD_LAKEHOUSE_ChangeRequest_Analytics
- **Workspace:** HIF-IA PowerBI Workspace
- **Theme:** CRM Dark Navy V2 (`theme/CRM_Dark_Navy_Theme_V2.json`)

### Infrastructure Health Page Visuals

| Visual | Fields | Notes |
|---|---|---|
| Slicer (tile) | `environment` | Filters all visuals — DEV / PROD |
| Gauge | `failed_system_jobs` | Scale 0–500, target line at 100 |
| Card | `active_users_current` | Display units = None, summarisation = Maximum |
| Gauge | `active_users_current` / `active_users_max` | User licence % |
| Gauge | `custom_entities_current` / `custom_entities_max` | Entity limit % |
| Card | `enabled_users` | Summarisation = Maximum |
| Card | `snapshot_date` | Last refresh — summarisation = Maximum |

### Adding the Theme

1. Open report in Power BI Desktop
2. **View → Themes dropdown → Browse for themes**
3. Select `theme/CRM_Dark_Navy_Theme_V2.json`

---

## Access

### Adding a New Report Viewer

New users require **both** of the following:

1. **Fabric Workspace** — add as Viewer via workspace Settings → Access
2. **Dataverse Security Role** — assign in Power Platform Admin Centre → esacontact (production) → Users → Manage security roles

Minimum Dataverse roles for full report access:
- `Basic User`
- `Marketing Professional` (required for Marketing pages)

---

## Outstanding Items

### ⚠️ Storage Capacity Data — BLOCKED

Database, file and log storage figures require the **Power Platform Administrator** role assigned in Microsoft Entra ID to the Service Principal.

**Admin request:**
> Assign the **Power Platform Administrator** role in Microsoft Entra ID to App Registration **Dynamics CRM** (ID: `28d48667-10ad-4563-93c3-499438dafbab`).  
> Steps: `entra.microsoft.com → Roles and administrators → Power Platform administrator → Add assignments → search App ID`

### Email Alerts — NOT YET CONFIGURED

To configure after publishing to Power BI service:
1. Open report in Power BI service
2. Click Failed System Jobs gauge → bell icon
3. Set: value > 100, frequency = once per day
4. Add recipient emails → Save

---

## Maintenance

### Secret Rotation

The Client Secret should be rotated every **12 months**:

1. Azure Portal → App Registrations → Dynamics CRM → Certificates & Secrets
2. Create new secret, copy value immediately
3. Update `CLIENT_SECRET` in Cell 2 of **both** notebooks
4. Run both notebooks manually to confirm they work
5. Delete the old secret

### Adding a New Environment (e.g. UAT)

1. Duplicate `PROD_Capacity_Notebook`, rename to `UAT_Capacity_Notebook`
2. Update Cell 2: `DATAVERSE_URL`, `ENVIRONMENT_ID`, `environment = 'UAT'`
3. Register Service Principal as Application User in the new environment:
   - Power Platform Admin Centre → Environments → select env → Settings → Application Users → New
   - Search for App ID `28d48667-10ad-4563-93c3-499438dafbab` → assign System Administrator role
4. Schedule the new notebook
5. New environment rows appear automatically in the table and Power BI slicer

### Monitoring the Monitors

Check regularly:
- Fabric workspace → notebook **Recent runs** — both should show ✅ daily
- CRM_Monitoring Lakehouse → `crm_health_snapshot` — should gain 2 rows/day
- If notebooks fail: check Client Secret expiry, Dataverse availability, Fabric capacity

---

## Fabric Resources

| Resource | Name |
|---|---|
| DEV Lakehouse | `dataverse_esacontactde_cds2_workspace_org40d0fe68` |
| PROD Lakehouse | `dataverse_esacontact_cds2_workspace_a94a4bf848e144bba608bb2eb51cbe` |
| Monitoring Lakehouse | `CRM_Monitoring` |
| Workspace ID | `6988ba37-18e0-4677-82f3-aab0aa8112cc` |
| CRM_Monitoring Lakehouse ID | `4eaaee48-ced4-4efc-9115-c094bf6646f6` |

---

## Change Log

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 19 May 2026 | Mike Kolling | Initial build — notebooks, Lakehouse table, Power BI Infrastructure Health page |

---

*For ESA Official Use Only (ESA UNCLASSIFIED)*
