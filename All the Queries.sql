/* ============================================================
   CUSTOMER INSIGHTS – REAL‑TIME MARKETING
   SQL4CDS DASHBOARD QUERY PACK

   Environment: Dataverse (CI – RTM)
   Tool: SQL4CDS
   Purpose:
     - Inventory
     - Governance
     - Archiving decisions
     - Power BI dataset source

   NOTES:
   - RTM consent is stored per contact point
   - Do NOT expect consent fields on contact table
   - All counts exclude inactive records unless stated
   ============================================================ */


/* ============================================================
   1. TOTAL NUMBER OF ACCOUNTS
   ============================================================ */
SELECT
    COUNT(*) AS TotalAccounts
FROM account

/* CHECKED */


/* ============================================================
   2. TOTAL NUMBER OF CONTACTS
   ============================================================ */
SELECT
    COUNT(*) AS TotalContacts
FROM contact

/* CHECKED */


/* ============================================================
   3. CONTACTS BY CONSENT (RTM‑CORRECT)
   - Uses contact point consent
   - Counts DISTINCT contacts
   ============================================================ */
SELECT
    p.msdynmkt_name          AS ConsentPurpose,
    c.msdynmkt_contactpointtypename  AS ChannelType,
    c.statecodename AS ConsentState,
    COUNT(DISTINCT c.msdynmkt_contactpointvalue ) AS TotalContacts
FROM msdynmkt_contactpointconsent4 c
JOIN msdynmkt_purpose p
    ON c.msdynmkt_purposeid = p.msdynmkt_purposeid
GROUP BY
    p.msdynmkt_name,
    c.msdynmkt_contactpointtypename,
    c.statecodename 
ORDER BY
    p.msdynmkt_name;

select top 10 * FROM msdynmkt_contactpointconsent4

/* CHECKED */


/* ============================================================
   4. TOTAL ONBOARDING / PROJECTS
   ============================================================ */
SELECT
    COUNT(*) AS TotalProjects
FROM cap_project

/* CHECKED */


SELECT
    COUNT(*) AS TotalOnBoardingProjects
FROM cap_esacontactonboarding

/* CHECKED */




SELECT
    distinct(cap_name)
FROM cap_esacontactonboarding


SELECT
    COUNT(DISTINCT o.cap_name) AS UniqueOnboardingProjectsWithUsers
FROM cap_esacontactonboarding o
INNER JOIN cap_cap_esacontactonboarding_systemuser osu
    ON osu.cap_esacontactonboardingid = o.cap_esacontactonboardingid
    
    
    
    
    SELECT
    o.cap_esacontactonboardingid,
    o.cap_name
FROM cap_esacontactonboarding o
WHERE NOT EXISTS (
    SELECT 1
    FROM cap_cap_esacontactonboarding_systemuser osu
    WHERE osu.cap_esacontactonboardingid = o.cap_esacontactonboardingid
)
ORDER BY o.cap_name
    

/* ============================================================
   5. PROJECT USERS – TOTAL AND PER PROJECT
   ============================================================ */

SELECT
    p.msdynmkt_name AS ProjectName,
    COUNT(u.msdynmkt_projectuserid) AS ProjectUsers
FROM msdynmkt_project p
LEFT JOIN msdynmkt_projectuser u
    ON p.msdynmkt_projectid = u.msdynmkt_projectid
GROUP BY p.msdynmkt_name
ORDER BY ProjectUsers DESC


/* 5. PROJECT USERS PER PROJECT */
SELECT
    p.cap_name AS ProjectName,
    COUNT(u.cap_cap_project_systemuserid) AS ProjectUsers
FROM cap_project p
LEFT JOIN cap_cap_project_systemuser u
    ON p.cap_projectid = u.cap_projectid
GROUP BY p.cap_name;

/* CHECKED */


/* Total users across all projects */

SELECT
    COUNT(DISTINCT cap_cap_project_systemuserid) AS TotalProjectUsers
FROM cap_cap_project_systemuser;

/* CHECKED */


/* ============================================================
   6. TOTAL CUSTOMER JOURNEYS (REAL‑TIME)
   ============================================================ */


select count(*) from msdyncrm_customerjourney  /* old outbound marketing needs to be changed to below */


SELECT
    statecodename,
    COUNT(*) AS TotalJourneys
FROM msdynmkt_journey
GROUP BY statecodename

UNION ALL

SELECT
    'TOTAL' AS statecodename,
    COUNT(*) AS TotalJourneys
FROM msdynmkt_journey;

/* CHECKED */

/* ============================================================
   7. TOTAL MARKETING PAGES
   ============================================================ */
SELECT
    COUNT(*) AS TotalMarketingPages
FROM msdyncrm_marketingpage

/* CHECKED */

/* ============================================================
   8. TOTAL MARKETING EMAILS
   ============================================================ */
SELECT
    COUNT(*) AS TotalMarketingEmails
FROM msdyncrm_marketingemail

/* CHECKED */

select count(*) from msdyncrm_customerjourney_msdyncrm_marketingemail

/* ============================================================
   9. TOTAL MARKETING FORMS
   ============================================================ */
SELECT
    COUNT(*) AS TotalMarketingForms
FROM msdyncrm_marketingform

/* CHECKED */

/* ============================================================
   10. TOTAL NEWSLETTERS
   - Adjust filter if you use a different categorisation
   ============================================================ */
SELECT
    COUNT(*) AS TotalNewsletters
FROM msdyncrm_marketingemail
WHERE msdyncrm_subject like '%Newsletter%';

/* CHECKED */

select distinct(msdyncrm_subject) FROM msdyncrm_marketingemail
/* ============================================================
   11. TOTAL EVENTS
   ============================================================ */
SELECT
    COUNT(*) AS TotalEvents
FROM msevtmgt_event

/* CHECKED */

/* ============================================================
   12. TOTAL EVENT REGISTRATIONS
   ============================================================ */
SELECT
    COUNT(*) AS TotalEventRegistrations
FROM msevtmgt_eventregistration

/* CHECKED */


/* ============================================================
   13. CUSTOMER VOICE PROJECTS
   ============================================================ */
SELECT
    COUNT(*) AS TotalCustomerVoiceProjects
FROM msfp_project



select count(*) from msfp_surveyresponse

/* CHECKED */


/* ============================================================
   14. TOTAL SUBSCRIBERS
   - Contacts with at least one ACTIVE consent
   ============================================================ */


listmember as i have done it in PBI - cannot run it in sql4cds but it is /* CHECKED */



this is similar but not the same 

SELECT
    COUNT(DISTINCT msdynmkt_contactpointvalue) AS TotalSubscribers
FROM msdynmkt_contactpointconsent4
WHERE msdynmkt_valuename='Opted In'




select top 10 * FROM msdynmkt_contactpointconsent4
/* ============================================================
   15. UNUSED / CLEAN‑UP CANDIDATES
   ============================================================ */
   
   
   
   
   need to check the rest below- 
   
   
   
   
   
   
   
   
   
   
   
   
   

-- 15a. Marketing Emails never sent
SELECT
    msdyncrm_name,
    createdon,
    msdyncrm_totalsent
FROM msdyncrm_marketingemail
WHERE statecode = 0
  AND msdynmkt_totalsent = 0
ORDER BY createdon;


select top 10 * FROM msdyncrm_marketingemail

-- 15b. Journeys not active
SELECT
    msdynmkt_name,
    statecode,
    modifiedon
FROM msdynmkt_journey
WHERE statecode <> 0;

-- 15c. Forms with no submissions
SELECT
    f.msdynmkt_name,
    COUNT(s.msdynmkt_formsubmissionid) AS Submissions
FROM msdynmkt_marketingform f
LEFT JOIN msdynmkt_formsubmission s
    ON f.msdynmkt_marketingformid = s.msdynmkt_marketingformid
GROUP BY
    f.msdynmkt_name
HAVING
    COUNT(s.msdynmkt_formsubmissionid) = 0;


/* ============================================================
   16. OWNERSHIP BREAKDOWN
   - Project owner
   - Project users
   ============================================================ */
SELECT
    p.msdynmkt_name AS ProjectName,
    owner.fullname AS ProjectOwner,
    user.fullname  AS ProjectUser
FROM msdynmkt_project p
LEFT JOIN systemuser owner
    ON p.ownerid = owner.systemuserid
LEFT JOIN msdynmkt_projectuser pu
    ON p.msdynmkt_projectid = pu.msdynmkt_projectid
LEFT JOIN systemuser user
    ON pu.msdynmkt_userid = user.systemuserid
ORDER BY
    p.msdynmkt_name;