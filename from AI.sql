/* ============================================================
   CUSTOMER INSIGHTS – REAL‑TIME MARKETING
   SQL4CDS DASHBOARD – VALIDATED AGAINST TENANT METADATA
   ============================================================ */


/* 1. TOTAL ACCOUNTS */
SELECT COUNT(*) AS TotalAccounts
FROM account
WHERE statecode = 0;


/* 2. TOTAL CONTACTS */
SELECT COUNT(*) AS TotalContacts
FROM contact
WHERE statecode = 0;


/* 3. CONTACTS BY CONSENT (RTM – CONTACT POINT BASED) */
SELECT
    p.msdynmkt_name AS ConsentPurpose,
    c.msdynmkt_channeltype AS ChannelType,
    c.msdynmkt_consentstate AS ConsentState,
    COUNT(DISTINCT c.msdynmkt_contactid) AS Contacts
FROM msdynmkt_contactpointconsent c
JOIN msdynmkt_purpose p
    ON c.msdynmkt_purposeid = p.msdynmkt_purposeid
GROUP BY
    p.msdynmkt_name,
    c.msdynmkt_channeltype,
    c.msdynmkt_consentstate;
    
    
    
    SELECT name
FROM metadata.attribute
WHERE entityname = 'msdynmkt_contactpointconsent'
ORDER BY name;


/* 4. TOTAL ONBOARDING PROJECTS (CUSTOM) */
SELECT COUNT(*) AS TotalProjects
FROM cap_projects
WHERE statecode = 0;




select * from cap_p

/* 6. CUSTOMER JOURNEYS (REAL‑TIME) */
SELECT COUNT(*) AS TotalJourneys
FROM msdynmkt_journey
WHERE statecode = 0;


/* 7. MARKETING PAGES */
SELECT COUNT(*) AS TotalMarketingPages
FROM msdynmkt_marketingpage
WHERE statecode = 0;


/* 8. MARKETING EMAILS */
SELECT COUNT(*) AS TotalMarketingEmails
FROM msdynmkt_marketingemail
WHERE statecode = 0;


/* 9. MARKETING FORMS */
SELECT COUNT(*) AS TotalMarketingForms
FROM msdynmkt_marketingform
WHERE statecode = 0;


/* 10. NEWSLETTERS (FLAG‑BASED) */
SELECT COUNT(*) AS TotalNewsletters
FROM msdynmkt_marketingemail
WHERE statecode = 0
  AND msdynmkt_isnewsletter = 1;


/* 11. EVENTS */
SELECT COUNT(*) AS TotalEvents
FROM msevtmgt_event
WHERE statecode = 0;


/* 12. EVENT REGISTRATIONS */
SELECT COUNT(*) AS TotalEventRegistrations
FROM msevtmgt_eventregistration
WHERE statecode = 0;


/* 13. CUSTOMER VOICE PROJECTS */
SELECT COUNT(*) AS TotalCustomerVoiceProjects
FROM msfp_project
WHERE statecode = 0;


/* 14. TOTAL SUBSCRIBERS (ANY ACTIVE CONSENT) */
SELECT COUNT(DISTINCT msdynmkt_contactid) AS TotalSubscribers
FROM msdynmkt_contactpointconsent
WHERE msdynmkt_consentstate = 1;


/* 15. UNUSED ITEMS – EMAILS NEVER SENT */
SELECT
    msdynmkt_name,
    createdon
FROM msdynmkt_marketingemail
WHERE msdynmkt_totalsent = 0
  AND statecode = 0;


/* 16. OWNERSHIP BREAKDOWN */
SELECT
    p.cap_name AS ProjectName,
    o.fullname AS ProjectOwner,
    u.fullname AS ProjectUser
FROM cap_projects p
LEFT JOIN systemuser o
    ON p.ownerid = o.systemuserid
LEFT JOIN cap_cap_project_systemuser pu
    ON p.cap_projectid = pu.cap_projectid
LEFT JOIN systemuser u
    ON pu.cap_cap_project_systemuserid = u.systemuserid;