# Fabric / Power BI Recovery Context

## Current working solution

Workspace:
- HIF-IA PowerBI Workspace

Semantic model:
- ESA_CRM_Analytics_PROD
- ID: bc60b18c-5251-40fb-a689-28a882e040cc

Report:
- V7PROD_LAKEHOUSE_ChangeRequest_Analytics

Primary Dataverse Lakehouse:
- dataverse_esacontact_cds2_workspace_a94a4bf848e144bba608bb2eb51cbe
- ID: ee1e74a0-c7a7-423e-8d8d-d4df8faa1b17

CRM Monitoring Lakehouse:
- CRM_Monitoring
- ID: 33d4b2b5-ad41-49c0-bc67-b3459f914d4a

## Fabric CLI

Fabric CLI version:
- ms-fabric-cli 1.7.0

Git Bash executable path:

C:/Users/Mike.Kolling/AppData/Roaming/Python/Python313/Scripts/fab.exe

For each Git Bash session:

export PATH="$PATH:/c/Users/Mike.Kolling/AppData/Roaming/Python/Python313/Scripts"

To persist:

echo 'export PATH="$PATH:/c/Users/Mike.Kolling/AppData/Roaming/Python/Python313/Scripts"' >> ~/.bashrc

Important:
- Python command is `py`, not `python`.
- In Git Bash avoid a leading slash in Fabric object paths because MSYS path conversion can convert it into C:/.
- Example:
  fab ls "HIF-IA PowerBI Workspace.Workspace"

## Semantic model editing workflow

Reliable workflow:

1. Export:
   fab export "HIF-IA PowerBI Workspace.Workspace/ESA_CRM_Analytics_PROD.SemanticModel" -o <existing-directory> -f

2. Edit exported TMDL locally.

3. Import:
   fab import \
     "HIF-IA PowerBI Workspace.Workspace/ESA_CRM_Analytics_PROD.SemanticModel" \
     -i <semantic-model-folder> \
     -f

4. Re-export and verify if required.

IMPORTANT:
- `-o` requires an existing directory.
- Never put backup `.tmdl` files inside `definition/tables`.
  Fabric treats every `.tmdl` file there as a model object and duplicate backups can make imports fail.
- Store backups outside the semantic model tree.

## Date slicer design

DateTable is intentionally disconnected for several areas.

Because Direct Lake DateTime fields and calculated relationship columns caused problems, the working approach is for measures to read:

VAR MinDate = MIN('DateTable'[Date])
VAR MaxDate = MAX('DateTable'[Date])

and filter the underlying DateTime field using:

createdon >= MinDate
createdon < MaxDate + 1

This approach is currently used for dashboard measures including:
- Total Accounts
- Total Contacts
- Total Marketing Forms
- TotalJourneys
- Total Marketing EMails
- Total Newsletters 2
- Total Customer Voice
- Total Event Registrations
- Total EVents
- Subscriber Count
- Average Subscriptions per Contact
- Consent card measures

## Customers page

The Date slicer controls the main customer/dashboard cards through date-aware measures.

The slicer had a Power BI Service rendering problem when Responsive was enabled.
Working setting:
- Responsive = Off

Marketing Insights:
- EmailSent uses Timestamp
- Added:
  - EmailYear
  - EmailQuarter
- Sent Emails chart shows approximately 35.9M records split by year/quarter.

## Consents page

Top consent cards are date-aware.

Consent basic-options bar chart uses:
- consenttable[ConsentType]
- measure: Consent Given Numeric Date

The measure filters contact IDs selected by the Date slicer and applies them to consenttable using TREATAS.

consentvaluecheck2 contains:
- MessageType
- Response
- RowCount

It does NOT contain dates or ContactID.

Text mappings:

MessageType:
- 534120000 = Email
- 534120001 = Text Message

Response:
- 534120000 = Not Set
- 534120001 = Opted In
- 534120002 = Opted Out

Calculated columns on the Direct Lake consentvaluecheck2 table were not a safe solution.

Working model now uses lookup tables:
- ConsentMessageType
- ConsentResponse

Relationships:
- consentvaluecheck2.MessageType -> ConsentMessageType.MessageType
- consentvaluecheck2.Response -> ConsentResponse.Response

Report visual references were patched to use:
- ConsentMessageType.MessageTypeText
- ConsentResponse.ResponseText
- consentvaluecheck2.RowCount remains the numeric value

## Infrastructure Health page

Environment is deliberately a disconnected semantic-model table containing:
- PROD
- DEV

Do NOT recreate a relationship between Environment and crm_health_snapshot.

A physical relationship caused Power BI to manufacture a `(Blank)` member in the Environment slicer.

The health measures instead use:

TREATAS(
    VALUES(Environment[Environment]),
    crm_health_snapshot[environment]
)

Current crm_health_snapshot data checked during recovery contained only a PROD row.

Therefore:
- PROD shows data
- DEV can legitimately be blank until a DEV snapshot exists
- Select all currently effectively returns PROD data

Health measures include:
- Health Active Users
- Health Active Users Max
- Health Failed System Jobs
- Health Custom Entities
- Health Custom Entities Max
- Health Enabled System Users
- Health Last Refreshed

Display measures were added for cards:
- Health Active Users Display
- Health Enabled System Users Display
- Health Last Refreshed Display

These return text so the Power BI new Card visual cannot abbreviate:
- 12498 -> 12.498K
- 5000 -> 5K

Last Refreshed display is formatted:
- dd/MM/yyyy

## Report definition editing

Report exported with:

fab export \
  "HIF-IA PowerBI Workspace.Workspace/V7PROD_LAKEHOUSE_ChangeRequest_Analytics.Report" \
  -o <existing-directory> \
  -f

Infrastructure Health page ID:
- 4858a9dcf02e6607fdee

Relevant visual IDs:
- 6307a4fbe27774f89940 - Custom Entities gauge
- 70853cb4d6a34d1cb6e7 - Active Users card
- 760ca804088be7b05c77 - Enabled System Users card
- 88b569c133f88285c169 - User License Usage gauge
- c092a925f342c295fb34 - Environment slicer
- ec6a5a8cd0a28fd66a10 - Failed System Jobs gauge
- f97f7846872f4f480c28 - Last Refreshed card

Consents page ID:
- 7ae3a5fe5cd85bae686e

Consent value table visual ID:
- a719f1fc84e13b683308

Its final intended field references are:
- ConsentMessageType.MessageTypeText
- ConsentResponse.ResponseText
- Sum(consentvaluecheck2.RowCount)

## Git repository

Local repo:
- C:/Users/Mike.Kolling/cr_powerbi

GitLab:
- https://gitlab.com/mikekollingesa/cr_powerbi.git

GitHub:
- https://github.com/mikekolling1966/cr_powerbi.git

Current remote configuration uses:
- origin fetch -> GitLab
- origin push -> GitLab
- origin second push URL -> GitHub

Therefore a normal:

git push origin main

can push the same commit to both remotes.

## Security

A client secret was exposed during recovery work.

Do not commit secrets, access tokens or credentials.

Before publishing history externally, scan the repository for:
- CLIENT_SECRET
- client_secret
- tokens
- PATs
- connection strings containing credentials

A previous history rewrite was performed to remove exposed secret material.

## Current recovery principle

The working semantic model and report definitions committed with this context file should be treated as the new source of truth.

Before future Fabric changes:
1. export current model/report
2. back up outside the model tree
3. make one controlled change
4. validate
5. import
6. re-export
7. commit working state
