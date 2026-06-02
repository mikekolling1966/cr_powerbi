# ESA CRM Analytics — Power BI Solution

> Full CRM analytics solution for the ESA D365 CRM (Dataverse) production environment. Covers customer and contact metrics, GDPR consent tracking, onboarding project monitoring, marketing performance, and infrastructure health. Data flows from Dataverse through Microsoft Fabric into a shared semantic model, surfaced in a single Power BI report.

---

## Overview

This solution connects to the ESA D365 CRM production Dataverse environment, pulls data into Microsoft Fabric via notebooks and dataflows, and exposes it through a five-page Power BI report.

| Page | What it shows |
|---|---|
| Customers | Accounts, contacts, segments, journeys, events, surveys |
| Consents | GDPR consent flags and email opt-in/opt-out status |
| Onboarding Projects | ESA onboarding project membership and user associations |
| MarketingInsights | Email delivery, bounce, and engagement metrics |
| Infrastructure Health | CRM platform capacity — users, entities, jobs, storage |

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  Dataverse (D365 CRM)                    │
│          esacontact.crm4.dynamics.com (PROD)             │
└────────────┬─────────────────────────┬───────────────────┘
             │                         │
      Notebooks (MSAL)         Dataflows Gen1/Gen2
             │                         │
    ┌────────▼─────────┐    ┌──────────▼──────────────────────────┐
    │  CRM_Monitoring  │    │  dataverse_esacontact_cds2_workspace │
    │    Lakehouse     │    │  _a94a4bf848e144bba608bb2eb51cbe     │
    │  crm_health_     │    │  (PROD Lakehouse)                    │
    │  snapshot        │    └──────────────┬──────────────────────┘
    │  (Delta table)   │                   │
    └────────┬─────────┘                   │
             │                             │
             └──────────────┬──────────────┘
                            │
                 ┌──────────▼──────────┐
                 │   Semantic Model    │
                 │  (Direct Lake /     │
                 │  pbiServiceLive)    │
                 │  ID: ebbd2012-...   │
                 └──────────┬──────────┘
                            │
              ┌─────────────▼──────────────┐
              │  V4PROD_LAKEHOUSE_          │
              │  ChangeRequest_Analytics   │
              │  (Power BI Report)         │
              │                            │
              │  • Customers               │
              │  • Consents                │
              │  • Onboarding Projects     │
              │  • MarketingInsights       │
              │  • Infrastructure Health   │
              └────────────────────────────┘
```

---

## Repository Structure

```
├── notebooks/
│   └── PROD_Capacity_Notebook.ipynb     # Infrastructure metrics — esacontact (PROD)
├── theme/
│   └── CRM_Dark_Navy_Theme_V2.json      # Power BI dark navy theme
├── docs/
│   └── CRM_Infrastructure_Monitoring_Solution.docx
└── README.md
```

---

## Data Ingestion

### 1. Capacity Notebooks — Infrastructure Health data

The `PROD_Capacity_Notebook` runs on a daily schedule via Fabric notebook scheduler. It authenticates to Dataverse using a Service Principal and writes infrastructure metrics to the `CRM_Monitoring` Lakehouse.

| Notebook | Environment | Target |
|---|---|---|
| `PROD_Capacity_Notebook` | esacontact (production) | `CRM_Monitoring` → `crm_health_snapshot` |

**Schedule:** Daily at 06:00 UTC. Each run appends one row to `crm_health_snapshot`.

#### Cell Structure



| Cell | Purpose |
|---|---|
| 1 | `%pip install msal requests pandas` — run this cell **alone first**, then Run All |
| 2 | Configuration — `TENANT_ID`, `CLIENT_ID`, `CLIENT_SECRET`, `DATAVERSE_URL`, `ENVIRONMENT_ID` |
| 3 | Authenticate via MSAL (Service Principal client credentials) |
| 4 | Fetch org resources — active users, custom entities, storage limits |
| 5 | Fetch failed system jobs count |
| 6 | Fetch enabled users count |
| 7 | Fetch plugin execution / crash stats |
| 8 | Build pandas DataFrame with `environment` column |
| 9 | Write to Delta table via PySpark `saveAsTable` with `mergeSchema=true` |
| 10 | Verify — SELECT from table to confirm write |

> ⚠️ Due to the pip install cell triggering a kernel restart, always run in two steps:
> 1. Run **Cell 1 only** and wait for kernel restart
> 2. Click **Run All** for remaining cells

#### API Endpoints Called

```
GET /api/data/v9.2/RetrieveOrganizationResources
GET /api/data/v9.2/asyncoperations?$filter=statecode eq 3 and statuscode eq 31&$count=true
GET /api/data/v9.2/systemusers?$filter=isdisabled eq false&$count=true
GET /api/data/v9.2/plugintypestatistics
```

---

### 2. Dataflows — CRM entity data

Two dataflows sync Dataverse entity data into the PROD Lakehouse. These feed the Customers, Consents, Onboarding Projects, and MarketingInsights pages.

| Dataflow | Type | Target Lakehouse |
|---|---|---|
| `cap_cap_esacontactonboarding_systemuser` | Gen2 (CI/CD) | PROD Lakehouse |
| `Get LOS Data` / `LoS1302_2` | Gen1 | Separate (LoS solution) |

The `cap_cap_esacontactonboarding_systemuser` dataflow populates the `cap_cap_esacontactonboarding_systemuser` table used by the Onboarding Projects page.

> ⚠️ `cap_cap_esacontactonboarding_systemuser` currently shows a refresh error in the workspace — check credentials and Dataverse connectivity if the Onboarding Projects page shows stale or missing data.

---

## Fabric Resources

| Resource | Name | ID |
|---|---|---|
| Workspace | HIF-IA PowerBI Workspace | `6988ba37-18e0-4677-82f3-aab0aa8112cc` |
| PROD Lakehouse | `dataverse_esacontact_cds2_workspace_a94a4bf848e144bba608bb2eb51cbe` | — |
| Monitoring Lakehouse | `CRM_Monitoring` | `4eaaee48-ced4-4efc-9115-c094bf6646f6` |
| Semantic Model | (pbiServiceLive) | `ebbd2012-021b-4460-8f42-5712c7c918a3` |

---

## Semantic Model

The report connects via a **live Power BI Service connection** (`pbiServiceLive`) to a shared semantic model. The model is not embedded in the `.pbix` — it lives in the service and is referenced by model ID `ebbd2012-021b-4460-8f42-5712c7c918a3`.

### Tables in the Model

The following Dataverse / Fabric tables are referenced across the report pages:

| Table | Source | Pages |
|---|---|---|
| `account` | Dataverse | Customers |
| `contact` | Dataverse | Customers, Consents |
| `DateTable` | Calculated | Customers |
| `msdyncrm_segment` | Dataverse (Marketing) | Customers |
| `msdynci_segmentmembership` | Dataverse (Customer Insights) | Customers |
| `SegmentSubscribed` | Derived | Customers |
| `msdynmkt_contactpointconsent4` | Dataverse (Marketing) | Customers, Consents |
| `msdynmkt_email` | Dataverse (Marketing) | Customers, MarketingInsights |
| `msdynmkt_journey` | Dataverse (Marketing) | Customers, MarketingInsights |
| `msdynmkt_marketingform` | Dataverse (Marketing) | Customers |
| `msevtmgt_event` | Dataverse (Events) | Customers |
| `msevtmgt_eventregistration` | Dataverse (Events) | Customers |
| `msfp_surveyresponse` | Dataverse (Customer Voice) | Customers, MarketingInsights |
| `consenttable` | Fabric / custom | Consents |
| `consentvaluecheck2` | Fabric / custom | Consents |
| `cap_esacontactonboarding` | Dataverse | Onboarding Projects |
| `cap_cap_esacontactonboarding_systemuser` | Dataverse / Dataflow | Onboarding Projects |
| `systemuser` | Dataverse | Onboarding Projects |
| `email` | Dataverse | MarketingInsights |
| `interactionforemail` | Dataverse | MarketingInsights |
| `EmailSent` | Fabric / derived | MarketingInsights |
| `EmailBounced` | Fabric / derived | MarketingInsights |
| `EmailHardBounced` | Fabric / derived | MarketingInsights |
| `EmailSoftBounced` | Fabric / derived | MarketingInsights |
| `EmailDelivered` | Fabric / derived | MarketingInsights |
| `EmailOpened` | Fabric / derived | MarketingInsights |
| `EmailAddressOptedOut` | Fabric / derived | MarketingInsights |
| `EmailBlockBounced` | Fabric / derived | MarketingInsights |
| `EmailBlockedByUnsubscription` | Fabric / derived | MarketingInsights |
| `EmailBlockedByUser` | Fabric / derived | MarketingInsights |
| `EmailBlockedInvalidRecipientAddress` | Fabric / derived | MarketingInsights |
| `EmailSendingFailed` | Fabric / derived | MarketingInsights |
| `crm_health_snapshot` | CRM_Monitoring Lakehouse | Infrastructure Health |

### Report-level DAX Measures

Two measures are defined at report level (model extensions), not in the semantic model itself:

```dax
-- Table: cap_esacontactonboarding
Users Associated to an Onboarding Project =
COUNTROWS(
    DISTINCT(
        SELECTCOLUMNS(
            RELATEDTABLE('cap_cap_esacontactonboarding_systemuser'),
            "systemuserid",
            'cap_cap_esacontactonboarding_systemuser'[systemuserid]
        )
    )
)

-- Table: crm_health_snapshot
Alert Threshold = 100
Failed Jobs Max = 500
```

---

## Report Pages

### Page 1 — Customers

Date-sliced summary of CRM activity.

| Visual | Type | Fields |
|---|---|---|
| Total Accounts Added | Card | `account.Total Accounts` |
| Total Contacts Added | Card | `contact.Total Contacts` |
| Duplicate Contacts | Card | `contact.Number of Duplicate Contacts` |
| Subscriber Count | Card | `msdynmkt_contactpointconsent4.Subscriber Count` |
| Average Subscriptions per Contact | Card | `msdyncrm_segment.Average Subscriptions per Contact` |
| Total Journeys | Card | `msdynmkt_journey.TotalJourneys` |
| Total Newsletters | Card | `msdynmkt_email.Total Newsletters 2` |
| Total Marketing Forms | Card | `msdynmkt_marketingform.Total Marketing Forms` |
| Total Events | Card | `msevtmgt_event.Total EVents` |
| Total Event Registrations | Card | `msevtmgt_eventregistration.Total Event Registrations` |
| Total Customer Voice | Card | `msfp_surveyresponse.Total Customer Voice` |
| Total Marketing Emails | Card | `msdynmkt_email.Total Marketing EMails` |
| Date Slicer | Slicer | `DateTable.Date` |

---

### Page 2 — Consents

GDPR consent status across the contact base.

| Visual | Type | Fields |
|---|---|---|
| GDPR Consent Flags | Multi-card | `contact`: Do Not Track, No Bulk Postal Mail, No Email, No Phone, No Postal Mail, No Bulk Email |
| Email Consent Summary | Multi-card | `msdynmkt_contactpointconsent4`: Not Set, Opted Out, Subscribers, Subscriber Count |
| Consent Given — basic Contact Options | Column chart | `consenttable.ConsentType` |
| Consent Detail | Table | `consentvaluecheck2.MessageType`, `consentvaluecheck2.Response` |

---

### Page 3 — Onboarding Projects

Tracks ESA onboarding projects and the system users assigned to them.

| Visual | Type | Fields |
|---|---|---|
| Unique Projects | Card | `cap_esacontactonboarding.Unique Project Names` |
| Number of Projects | Card | `cap_esacontactonboarding.Number of Projects` |
| Onboarding Projects | Table | `cap_esacontactonboarding.cap_name`, `Users Associated to an Onboarding Project` |
| Users Associated to an Onboarding Project | Card | DAX measure (see above) |

**Data source:** `cap_esacontactonboarding` and `cap_cap_esacontactonboarding_systemuser` tables, synced via the `cap_cap_esacontactonboarding_systemuser` Gen2 dataflow.

---

### Page 4 — MarketingInsights

Email delivery and engagement metrics. Note: the four bounce/sent visuals pull from derived `Email*` tables — these must be present and populated in the semantic model for these cards to show data.

| Visual | Type | Fields |
|---|---|---|
| Total Journeys | Card | `msdynmkt_journey.TotalJourneys` |
| Total Marketing Emails | Card | `msdynmkt_email.Total Marketing EMails` |
| Bounced Emails | Card | `EmailBounced.ContactId` (COUNT) |
| Sent Emails | Card | `EmailSent.ContactId` (COUNT) |
| Hard Bounced Emails | Card | `EmailHardBounced.ContactId` (COUNT) |
| Soft Bounced Emails | Card | `EmailSoftBounced.ContactId` (COUNT) |
| Customer Surveys | Card | `msfp_surveyresponse.Total Customer Voice` |
| Total Newsletters | Card | `msdynmkt_email.Total Newsletters 2` |

> ⚠️ Bounced/Sent visuals currently show no field bindings in the report definition, which typically means the underlying `Email*` tables are not connected or are empty in the semantic model. Verify these tables exist and are populated in the Lakehouse.

---

### Page 5 — Infrastructure Health

Daily snapshot of CRM platform capacity metrics. Sourced entirely from `crm_health_snapshot` in the `CRM_Monitoring` Lakehouse.

| Visual | Type | Fields |
|---|---|---|
| Environment | Slicer | `crm_health_snapshot.environment` |
| Failed System Jobs | Gauge | `failed_system_jobs` — scale 0–500, target line at 100 |
| Active Users | Card | `active_users_current` (MAX) |
| User License Usage | Gauge | `active_users_current` / `active_users_max` |
| Custom Entities Usage | Gauge | `custom_entities_current` / `custom_entities_max` |
| Enabled System Users | Card | `enabled_users` (MAX) |
| Last Refreshed | Card | `snapshot_date` (MAX) |

---

## crm_health_snapshot Table

**Location:** `CRM_Monitoring` Lakehouse → Tables → `crm_health_snapshot`  
**Format:** Delta table, append mode  
**Growth rate:** 1 row/day

| Column | Type | Description |
|---|---|---|
| `environment` | string | Environment identifier (e.g. `PROD`) |
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
| Dataverse role | System Administrator on esacontact |

### Configuration — PROD Notebook (Cell 2)

```python
TENANT_ID      = '9a5cacd0-2bef-4dd7-ac5c-7ebe1f54f495'
CLIENT_ID      = '28d48667-10ad-4563-93c3-499438dafbab'
CLIENT_SECRET  = '<secret>'
DATAVERSE_URL  = 'https://esacontact.crm4.dynamics.com'
ENVIRONMENT_ID = '2c31dc4f-f142-4c34-b691-e24228103ea2'
environment    = 'PROD'
```

> ⚠️ **Never commit the actual `CLIENT_SECRET` value to GitLab.** Replace with `<secret>` in committed files and store the real value securely.

---

## Theme

The report uses a custom dark navy theme.

| Property | Value |
|---|---|
| Name | CRM Dark Navy |
| Background | `#1a2744` |
| Foreground | `#ffffff` |
| Primary data colour | `#4a90d9` |
| File | `theme/CRM_Dark_Navy_Theme_V2.json` |

**To apply in Power BI Desktop:** View → Themes dropdown → Browse for themes → select `theme/CRM_Dark_Navy_Theme_V2.json`

---

## Power BI Report

| Property | Value |
|---|---|
| Name | `V4PROD_LAKEHOUSE_ChangeRequest_Analytics` |
| Workspace | HIF-IA PowerBI Workspace |
| Connection type | `pbiServiceLive` (live connection to semantic model) |
| Semantic model ID | `ebbd2012-021b-4460-8f42-5712c7c918a3` |
| PBI Service Model ID | `8631054` |

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

### ⚠️ MarketingInsights Email Bounce Visuals — BROKEN

The Bounced, Sent, Hard Bounced, and Soft Bounced cards on the MarketingInsights page have no live field bindings. The `EmailBounced`, `EmailSent`, `EmailHardBounced`, and `EmailSoftBounced` derived tables need to be verified as present and populated in the semantic model.

### ⚠️ cap_cap_esacontactonboarding_systemuser Dataflow — REFRESH ERROR

The Gen2 dataflow syncing onboarding systemuser data is currently showing a refresh error in the workspace. This will cause the Onboarding Projects page to show stale data. Check dataflow credentials and Dataverse connectivity.

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
3. Update `CLIENT_SECRET` in Cell 2 of the PROD notebook
4. Run the notebook manually to confirm it works
5. Delete the old secret

### Monitoring the Monitors

Check regularly:
- Fabric workspace → notebook **Recent runs** — both should show ✅ daily
- CRM_Monitoring Lakehouse → `crm_health_snapshot` — should gain 1 row/day
- If notebooks fail: check Client Secret expiry, Dataverse availability, Fabric capacity

### Adding a New Environment (e.g. UAT)

1. Duplicate `PROD_Capacity_Notebook`, rename to `UAT_Capacity_Notebook`
2. Update Cell 2: `DATAVERSE_URL`, `ENVIRONMENT_ID`, `environment = 'UAT'`
3. Register Service Principal as Application User in the new environment:
   - Power Platform Admin Centre → Environments → select env → Settings → Application Users → New
   - Search for App ID `28d48667-10ad-4563-93c3-499438dafbab` → assign System Administrator role
4. Schedule the new notebook
5. New environment rows appear automatically in the table and Power BI slicer

---

## Change Log

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 19 May 2026 | Mike Kolling | Initial build — notebooks, Lakehouse table, Power BI Infrastructure Health page |
| 1.1 | 02 Jun 2026 | — | README expanded to cover full solution — all 5 report pages, all Dataverse tables, semantic model, dataflow dependencies, known issues |

---

*For ESA Official Use Only (ESA UNCLASSIFIED)*
