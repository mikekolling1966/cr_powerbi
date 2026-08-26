/*
===============================================================================
Power BI Validation Query Pack
Report: V7PROD_LAKEHOUSE_ChangeRequest_Analytics
Semantic model: ESA_CRM_Analytics_PROD
Generated: 2026-08-26

PURPOSE
-------
Run this script against the Fabric SQL analytics endpoint for the Dataverse
Lakehouse to independently validate the values shown in the Power BI report.

IMPORTANT
---------
1. Set @FromDate and @ToDate to the same dates selected in the Power BI Date
   slicer. @ToDate is INCLUSIVE; the queries use < DATEADD(day,1,@ToDate),
   matching the DAX measures used in the semantic model.

2. Most report measures use CREATEDON for date filtering.

3. The Infrastructure Health data comes from CRM_Monitoring rather than the
   Dataverse Lakehouse. Those queries are in a separate section near the end.
   If three-part names are not enabled in your SQL endpoint, run that section
   while connected directly to the CRM_Monitoring SQL analytics endpoint.

4. The Environment dimension in Power BI is intentionally disconnected.
   Environment filtering is implemented with TREATAS in DAX. The SQL checks
   reproduce that by filtering crm_health_snapshot.environment directly.

5. Some visuals are helper-table based (consenttable / consentvaluecheck2).
   Their SQL checks query those helper tables directly, because that is the
   closest independent equivalent of the visual.

===============================================================================
*/

SET NOCOUNT ON;

DECLARE @FromDate date = '2015-01-01';
DECLARE @ToDate   date = '2030-12-31';

-- Infrastructure Health only. Set to NULL for all environments.
DECLARE @Environment varchar(20) = NULL;  -- e.g. 'PROD' or 'DEV'

PRINT 'Power BI validation query pack';
PRINT CONCAT('Date range: ', CONVERT(varchar(10), @FromDate, 120),
             ' to ', CONVERT(varchar(10), @ToDate, 120));
PRINT '===============================================================================';


/* ============================================================================
   PAGE 1 - CUSTOMERS
   ============================================================================ */

PRINT 'PAGE: Customers';

/* ---------------------------------------------------------------------------
   C01 - Total Accounts Added
   Power BI measure: account[Total Accounts Date Test]
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Total Accounts Added' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.account
WHERE createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   C02 - Total Contacts Added
   Date-aware contact count.
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Total Contacts Added' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.contact
WHERE createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   C03 - Total Contacts - all rows (useful cross-check)
   This intentionally ignores the date slicer.
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Total Contacts All Time' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.contact;


/* ---------------------------------------------------------------------------
   C04 - Subscriber Count
   Power BI logic:
     DISTINCTCOUNT(msdynmkt_contactpointvalue)
     msdynmkt_value = 534120001
     topic id is not blank
     date filtered by createdon
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Subscriber Count' AS Validation,
    COUNT_BIG(DISTINCT msdynmkt_contactpointvalue) AS SQLValue
FROM dbo.msdynmkt_contactpointconsent4
WHERE msdynmkt_value = 534120001
  AND msdynmkt_topicid IS NOT NULL
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   C05 - Average Subscriptions per Contact
   Power BI uses AVERAGE(msdynmkt_segment[msdynmkt_membercount])
   with date filtering on segment.createdon.
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Average Subscriptions per Contact' AS Validation,
    AVG(CAST(msdynmkt_membercount AS decimal(38,4))) AS SQLValue
FROM dbo.msdynmkt_segment
WHERE createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   C06 - Total Journeys
   Power BI measure: TotalJourneys
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Total Journeys' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.msdynmkt_journey
WHERE createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   C07 - Total Marketing Forms
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Total Marketing Forms' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.msdynmkt_marketingform
WHERE createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   C08 - Total Marketing Emails
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Total Marketing Emails' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.msdynmkt_email
WHERE createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   C09 - Total Newsletters
   Power BI searches "Newsletter" in msdynmkt_subject.
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Total Newsletters' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.msdynmkt_email
WHERE msdynmkt_subject LIKE '%Newsletter%'
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   C10 - Total Customer Voice / Survey Responses
   Power BI measure uses msfp_submitdate.
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Total Customer Voice' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.msfp_surveyresponse
WHERE msfp_submitdate >= @FromDate
  AND msfp_submitdate < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   C11 - Total Event Registrations
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Total Event Registrations' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.msevtmgt_eventregistration
WHERE createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   C12 - Total Events
   --------------------------------------------------------------------------- */
SELECT
    'Customers - Total Events' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.msevtmgt_event
WHERE createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ============================================================================
   PAGE 2 - CONSENTS
   ============================================================================ */

PRINT 'PAGE: Consents';

/* ---------------------------------------------------------------------------
   S01-S06 - Basic Contact Consent Cards
   The Power BI measures count contact rows where each boolean is TRUE.
   --------------------------------------------------------------------------- */
SELECT
    'Consents - GDPR Do Not Track' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.contact
WHERE msgdpr_donottrack = 1
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);

SELECT
    'Consents - No Bulk Email' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.contact
WHERE donotbulkemail = 1
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);

SELECT
    'Consents - No Bulk Postal Mail' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.contact
WHERE donotbulkpostalmail = 1
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);

SELECT
    'Consents - No Email' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.contact
WHERE donotemail = 1
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);

SELECT
    'Consents - No Phone' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.contact
WHERE donotphone = 1
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);

SELECT
    'Consents - No Postal Mail' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.contact
WHERE donotpostalmail = 1
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   S07 - Total Email Not Set
   Current RTM consent choice codes:
     Contact point type 534120000 = Email
     msdynmkt_value NULL            = Not Set
   --------------------------------------------------------------------------- */
SELECT
    'Consents - Total Email Not Set' AS Validation,
    COUNT_BIG(DISTINCT msdynmkt_contactpointvalue) AS SQLValue
FROM dbo.msdynmkt_contactpointconsent4
WHERE msdynmkt_contactpointtype = 534120000
  AND msdynmkt_value IS NULL
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   S08 - Total Email Opted Out
   --------------------------------------------------------------------------- */
SELECT
    'Consents - Total Email Opted Out' AS Validation,
    COUNT_BIG(DISTINCT msdynmkt_contactpointvalue) AS SQLValue
FROM dbo.msdynmkt_contactpointconsent4
WHERE msdynmkt_contactpointtype = 534120000
  AND msdynmkt_value = 534120002
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   S09 - Total Email Subscribers
   --------------------------------------------------------------------------- */
SELECT
    'Consents - Total Email Subscribers' AS Validation,
    COUNT_BIG(DISTINCT msdynmkt_contactpointvalue) AS SQLValue
FROM dbo.msdynmkt_contactpointconsent4
WHERE msdynmkt_contactpointtype = 534120000
  AND msdynmkt_value = 534120001
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   S10 - Subscriber Count
   Same measure also appears on Customers.
   --------------------------------------------------------------------------- */
SELECT
    'Consents - Subscriber Count' AS Validation,
    COUNT_BIG(DISTINCT msdynmkt_contactpointvalue) AS SQLValue
FROM dbo.msdynmkt_contactpointconsent4
WHERE msdynmkt_value = 534120001
  AND msdynmkt_topicid IS NOT NULL
  AND createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   S11 - Consent Given - Basic Contact Options bar chart
   Power BI uses consenttable[ConsentType] and the date-aware measure:
       SUM(consenttable[ConsentGivenNumeric])
   over contacts created inside the Date slicer.
   --------------------------------------------------------------------------- */
SELECT
    ct.ConsentType,
    SUM(CAST(ct.ConsentGivenNumeric AS bigint)) AS SQLValue
FROM dbo.consenttable AS ct
INNER JOIN dbo.contact AS c
    ON c.contactid = ct.ContactID
WHERE c.createdon >= @FromDate
  AND c.createdon < DATEADD(day, 1, @ToDate)
GROUP BY ct.ConsentType
ORDER BY ct.ConsentType;


/* ---------------------------------------------------------------------------
   S12 - Consent MessageType / Response table
   This visual is deliberately NOT date-filtered at present.

   Mapping:
     MessageType 534120000 = Email
     MessageType 534120001 = Text Message

     Response 534120000 = Not Set
     Response 534120001 = Opted In
     Response 534120002 = Opted Out
   --------------------------------------------------------------------------- */
SELECT
    CASE MessageType
        WHEN 534120000 THEN 'Email'
        WHEN 534120001 THEN 'Text Message'
        ELSE 'Unknown'
    END AS MessageType,
    CASE Response
        WHEN 534120000 THEN 'Not Set'
        WHEN 534120001 THEN 'Opted In'
        WHEN 534120002 THEN 'Opted Out'
        ELSE 'Unknown'
    END AS Response,
    SUM(CAST(RowCount AS bigint)) AS SQLValue
FROM dbo.consentvaluecheck2
GROUP BY MessageType, Response
ORDER BY
    CASE MessageType
        WHEN 534120000 THEN 1
        WHEN 534120001 THEN 2
        ELSE 99
    END,
    Response;


/* ============================================================================
   PAGE 3 - ONBOARDING PROJECTS
   ============================================================================ */

PRINT 'PAGE: Onboarding Projects';

/* ---------------------------------------------------------------------------
   O01 - Total Onboarding Projects
   --------------------------------------------------------------------------- */
SELECT
    'Onboarding - Total Onboarding Projects' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.cap_esacontactonboarding
WHERE createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   O02 - Total Projects
   --------------------------------------------------------------------------- */
SELECT
    'Onboarding - Total Projects' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.cap_project
WHERE createdon >= @FromDate
  AND createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   O03 - Onboarding projects with assigned users
   --------------------------------------------------------------------------- */
SELECT
    'Onboarding - Projects With Users' AS Validation,
    COUNT_BIG(DISTINCT o.cap_esacontactonboardingid) AS SQLValue
FROM dbo.cap_esacontactonboarding AS o
INNER JOIN dbo.cap_cap_esacontactonboarding_systemuser AS osu
    ON osu.cap_esacontactonboardingid = o.cap_esacontactonboardingid
WHERE o.createdon >= @FromDate
  AND o.createdon < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   O04 - Project users per project
   --------------------------------------------------------------------------- */
SELECT
    p.cap_name AS ProjectName,
    COUNT_BIG(u.cap_cap_project_systemuserid) AS SQLValue
FROM dbo.cap_project AS p
LEFT JOIN dbo.cap_cap_project_systemuser AS u
    ON u.cap_projectid = p.cap_projectid
WHERE p.createdon >= @FromDate
  AND p.createdon < DATEADD(day, 1, @ToDate)
GROUP BY p.cap_projectid, p.cap_name
ORDER BY SQLValue DESC, ProjectName;


/* ---------------------------------------------------------------------------
   O05 - Onboarding users per onboarding project
   --------------------------------------------------------------------------- */
SELECT
    o.cap_name AS OnboardingProject,
    COUNT_BIG(osu.cap_cap_esacontactonboarding_systemuserid) AS SQLValue
FROM dbo.cap_esacontactonboarding AS o
LEFT JOIN dbo.cap_cap_esacontactonboarding_systemuser AS osu
    ON osu.cap_esacontactonboardingid = o.cap_esacontactonboardingid
WHERE o.createdon >= @FromDate
  AND o.createdon < DATEADD(day, 1, @ToDate)
GROUP BY o.cap_esacontactonboardingid, o.cap_name
ORDER BY SQLValue DESC, OnboardingProject;


/* ---------------------------------------------------------------------------
   O06 - Onboarding projects with no assigned users
   Diagnostic query for visual totals.
   --------------------------------------------------------------------------- */
SELECT
    o.cap_esacontactonboardingid,
    o.cap_name
FROM dbo.cap_esacontactonboarding AS o
WHERE o.createdon >= @FromDate
  AND o.createdon < DATEADD(day, 1, @ToDate)
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.cap_cap_esacontactonboarding_systemuser AS osu
      WHERE osu.cap_esacontactonboardingid = o.cap_esacontactonboardingid
  )
ORDER BY o.cap_name;


/* ============================================================================
   PAGE 4 - MARKETING INSIGHTS
   ============================================================================ */

PRINT 'PAGE: Marketing Insights';

/* ---------------------------------------------------------------------------
   M01 - Email Sent total
   --------------------------------------------------------------------------- */
SELECT
    'Marketing Insights - Emails Sent' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.EmailSent
WHERE [Timestamp] >= @FromDate
  AND [Timestamp] < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   M02 - Emails Sent by Year / Quarter
   Mirrors the chart using EmailYear / EmailQuarter.
   --------------------------------------------------------------------------- */
SELECT
    YEAR([Timestamp]) AS EmailYear,
    CONCAT('Q', DATEPART(quarter, [Timestamp])) AS EmailQuarter,
    COUNT_BIG(*) AS SQLValue
FROM dbo.EmailSent
WHERE [Timestamp] >= @FromDate
  AND [Timestamp] < DATEADD(day, 1, @ToDate)
GROUP BY
    YEAR([Timestamp]),
    DATEPART(quarter, [Timestamp])
ORDER BY
    EmailYear,
    DATEPART(quarter, [Timestamp]);


/* ---------------------------------------------------------------------------
   M03 - Email Bounced
   --------------------------------------------------------------------------- */
SELECT
    'Marketing Insights - Email Bounced' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.EmailBounced
WHERE [Timestamp] >= @FromDate
  AND [Timestamp] < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   M04 - Email Hard Bounced
   --------------------------------------------------------------------------- */
SELECT
    'Marketing Insights - Email Hard Bounced' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.EmailHardBounced
WHERE [Timestamp] >= @FromDate
  AND [Timestamp] < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   M05 - Email Soft Bounced
   --------------------------------------------------------------------------- */
SELECT
    'Marketing Insights - Email Soft Bounced' AS Validation,
    COUNT_BIG(*) AS SQLValue
FROM dbo.EmailSoftBounced
WHERE [Timestamp] >= @FromDate
  AND [Timestamp] < DATEADD(day, 1, @ToDate);


/* ---------------------------------------------------------------------------
   M06 - Bounce summary in one result set
   --------------------------------------------------------------------------- */
SELECT 'Sent' AS EmailOutcome, COUNT_BIG(*) AS SQLValue
FROM dbo.EmailSent
WHERE [Timestamp] >= @FromDate
  AND [Timestamp] < DATEADD(day,1,@ToDate)

UNION ALL

SELECT 'Bounced', COUNT_BIG(*)
FROM dbo.EmailBounced
WHERE [Timestamp] >= @FromDate
  AND [Timestamp] < DATEADD(day,1,@ToDate)

UNION ALL

SELECT 'Hard Bounced', COUNT_BIG(*)
FROM dbo.EmailHardBounced
WHERE [Timestamp] >= @FromDate
  AND [Timestamp] < DATEADD(day,1,@ToDate)

UNION ALL

SELECT 'Soft Bounced', COUNT_BIG(*)
FROM dbo.EmailSoftBounced
WHERE [Timestamp] >= @FromDate
  AND [Timestamp] < DATEADD(day,1,@ToDate);


/* ============================================================================
   PAGE 5 - INFRASTRUCTURE HEALTH
   ----------------------------------------------------------------------------
   Run this section against the CRM_Monitoring SQL analytics endpoint if
   crm_health_snapshot is not visible from the Dataverse Lakehouse endpoint.
   ============================================================================ */

PRINT 'PAGE: Infrastructure Health';

/* ---------------------------------------------------------------------------
   I00 - Available environments / snapshots
   --------------------------------------------------------------------------- */
SELECT
    environment,
    COUNT_BIG(*) AS SnapshotRows,
    MIN(snapshot_date) AS FirstSnapshot,
    MAX(snapshot_date) AS LastSnapshot
FROM dbo.crm_health_snapshot
GROUP BY environment
ORDER BY environment;


/* ---------------------------------------------------------------------------
   I01 - Failed System Jobs
   Power BI measure uses MAX(failed_system_jobs).
   --------------------------------------------------------------------------- */
SELECT
    'Infrastructure - Failed System Jobs' AS Validation,
    MAX(failed_system_jobs) AS SQLValue
FROM dbo.crm_health_snapshot
WHERE snapshot_date >= @FromDate
  AND snapshot_date < DATEADD(day, 1, @ToDate)
  AND (@Environment IS NULL OR environment = @Environment);


/* ---------------------------------------------------------------------------
   I02 - Alert Threshold / Failed Jobs Max
   These are fixed semantic-model measures: 80 and 100.
   --------------------------------------------------------------------------- */
SELECT
    'Infrastructure - Alert Threshold' AS Validation,
    CAST(80 AS bigint) AS SQLValue
UNION ALL
SELECT
    'Infrastructure - Failed Jobs Max',
    CAST(100 AS bigint);


/* ---------------------------------------------------------------------------
   I03 - Active Users
   --------------------------------------------------------------------------- */
SELECT
    'Infrastructure - Active Users' AS Validation,
    MAX(active_users_current) AS SQLValue
FROM dbo.crm_health_snapshot
WHERE snapshot_date >= @FromDate
  AND snapshot_date < DATEADD(day, 1, @ToDate)
  AND (@Environment IS NULL OR environment = @Environment);


/* ---------------------------------------------------------------------------
   I04 - User License Usage gauge
   Value = active_users_current
   Maximum = active_users_max
   --------------------------------------------------------------------------- */
SELECT
    'Infrastructure - User License Usage' AS Validation,
    MAX(active_users_current) AS CurrentValue,
    MAX(active_users_max) AS MaximumValue,
    CASE
        WHEN MAX(active_users_max) = 0 THEN NULL
        ELSE CAST(MAX(active_users_current) AS decimal(18,4))
             / NULLIF(MAX(active_users_max), 0)
    END AS UsageRatio
FROM dbo.crm_health_snapshot
WHERE snapshot_date >= @FromDate
  AND snapshot_date < DATEADD(day, 1, @ToDate)
  AND (@Environment IS NULL OR environment = @Environment);


/* ---------------------------------------------------------------------------
   I05 - Custom Entities Usage gauge
   --------------------------------------------------------------------------- */
SELECT
    'Infrastructure - Custom Entities Usage' AS Validation,
    MAX(custom_entities_current) AS CurrentValue,
    MAX(custom_entities_max) AS MaximumValue,
    CASE
        WHEN MAX(custom_entities_max) = 0 THEN NULL
        ELSE CAST(MAX(custom_entities_current) AS decimal(18,4))
             / NULLIF(MAX(custom_entities_max), 0)
    END AS UsageRatio
FROM dbo.crm_health_snapshot
WHERE snapshot_date >= @FromDate
  AND snapshot_date < DATEADD(day, 1, @ToDate)
  AND (@Environment IS NULL OR environment = @Environment);


/* ---------------------------------------------------------------------------
   I06 - Enabled System Users
   --------------------------------------------------------------------------- */
SELECT
    'Infrastructure - Enabled System Users' AS Validation,
    MAX(enabled_users) AS SQLValue
FROM dbo.crm_health_snapshot
WHERE snapshot_date >= @FromDate
  AND snapshot_date < DATEADD(day, 1, @ToDate)
  AND (@Environment IS NULL OR environment = @Environment);


/* ---------------------------------------------------------------------------
   I07 - Last Refreshed
   Power BI display format: dd/MM/yyyy.
   --------------------------------------------------------------------------- */
SELECT
    'Infrastructure - Last Refreshed' AS Validation,
    MAX(snapshot_date) AS SQLDateTime,
    CONVERT(char(10), MAX(snapshot_date), 103) AS PowerBIDisplayValue
FROM dbo.crm_health_snapshot
WHERE snapshot_date >= @FromDate
  AND snapshot_date < DATEADD(day, 1, @ToDate)
  AND (@Environment IS NULL OR environment = @Environment);


/* ============================================================================
   EXTRA DATA-QUALITY CHECKS
   ============================================================================ */

PRINT 'DATA QUALITY CHECKS';

/* DQ01 - Date ranges available in core tables */
SELECT 'account' AS TableName, MIN(createdon) AS MinDate, MAX(createdon) AS MaxDate, COUNT_BIG(*) AS Rows
FROM dbo.account
UNION ALL
SELECT 'contact', MIN(createdon), MAX(createdon), COUNT_BIG(*) FROM dbo.contact
UNION ALL
SELECT 'msdynmkt_journey', MIN(createdon), MAX(createdon), COUNT_BIG(*) FROM dbo.msdynmkt_journey
UNION ALL
SELECT 'msdynmkt_email', MIN(createdon), MAX(createdon), COUNT_BIG(*) FROM dbo.msdynmkt_email
UNION ALL
SELECT 'msevtmgt_event', MIN(createdon), MAX(createdon), COUNT_BIG(*) FROM dbo.msevtmgt_event
UNION ALL
SELECT 'msevtmgt_eventregistration', MIN(createdon), MAX(createdon), COUNT_BIG(*) FROM dbo.msevtmgt_eventregistration;


/* DQ02 - consentvaluecheck2 raw/unmapped codes */
SELECT
    MessageType,
    Response,
    SUM(CAST(RowCount AS bigint)) AS RowsForCombination
FROM dbo.consentvaluecheck2
WHERE MessageType NOT IN (534120000, 534120001)
   OR Response NOT IN (534120000, 534120001, 534120002)
   OR MessageType IS NULL
   OR Response IS NULL
GROUP BY MessageType, Response
ORDER BY MessageType, Response;


/* DQ03 - Consent helper-table contacts not found in contact */
SELECT
    COUNT_BIG(*) AS OrphanConsentTableRows
FROM dbo.consenttable AS ct
LEFT JOIN dbo.contact AS c
    ON c.contactid = ct.ContactID
WHERE c.contactid IS NULL;


/* DQ04 - Health rows by environment and date */
SELECT
    environment,
    CAST(snapshot_date AS date) AS SnapshotDate,
    COUNT_BIG(*) AS RowsPerDay
FROM dbo.crm_health_snapshot
GROUP BY environment, CAST(snapshot_date AS date)
ORDER BY SnapshotDate DESC, environment;


/* ============================================================================
   END
   ============================================================================ */
PRINT 'Validation query pack complete.';
