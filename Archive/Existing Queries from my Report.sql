1) Accounts and Contacts

Total Accounts Added
Visual: Card
Query:

FROM Account
SELECT [Total Accounts]
ORDER BY [Total Accounts] DESC

Total Contacts Added
Visual: Card
Query:

FROM Contact
SELECT [Total Contacts]
ORDER BY [Total Contacts] DESC

Consent Given
Visual: Column chart
Query:

FROM ConsentTable
SELECT
  SUM([ConsentGivenNumeric]),
  [ConsentType]
GROUP BY [ConsentType]
ORDER BY SUM([ConsentGivenNumeric]) DESC

Date slicer
Visual: Slicer
Query:

FROM DateTable
SELECT [Date]
ORDER BY [Date] ASC
2) Projects

Total Projects
Visual: Card
Query:

FROM cap_project
SELECT [Total Projects]
ORDER BY [Total Projects] DESC

Users Per Project by Project Name
Visual: Clustered column chart
Query:

FROM cap_project
SELECT
  [Users Per Project],
  [cap_name]
GROUP BY [cap_name]
ORDER BY [Users Per Project] DESC

Total Users
Visual: Card
Query:

FROM cap_project
SELECT [Total Users]
ORDER BY [Total Users] DESC

Onboarding Project Users
Visual: Card
Query:

FROM cap_esacontactonboarding
SELECT [Users Associated to an Onboarding Project]
ORDER BY [Users Associated to an Onboarding Project] DESC

Onboarding Projects
Visual: Table
Query:

FROM cap_esacontactonboarding
SELECT
  [cap_name],
  [Users Associated to an Onboarding Project]
ORDER BY [cap_name] ASC

Number of Projects with Users
Visual: Card
Query:

FROM cap_esacontactonboarding
SELECT [Unique Onboarding Projects with Users]
ORDER BY [Unique Onboarding Projects with Users] DESC
3) Marketing

A few of these cards do not have friendly titles stored in the layout, so I’m naming them by the field/measure they use.

Customer Journeys
Visual: Card
Query:

FROM msdyncrm_customerjourney
SELECT COUNTNONNULL([TotalJourneys])
ORDER BY COUNTNONNULL([TotalJourneys]) DESC

Marketing Pages
Visual: Card
Query:

FROM msdyncrm_marketingpage
SELECT COUNTNONNULL([Total Marketing Pages])
ORDER BY COUNTNONNULL([Total Marketing Pages]) DESC

Marketing Emails
Visual: Card
Query:

FROM msdyncrm_marketingemail
SELECT COUNTNONNULL([Total Marketing EMails])
ORDER BY COUNTNONNULL([Total Marketing EMails]) DESC

Marketing Forms
Visual: Card
Query:

FROM msdyncrm_marketingform
SELECT COUNTNONNULL([Total Marketing Forms])
ORDER BY COUNTNONNULL([Total Marketing Forms]) DESC

Total Newsletters
Visual: Card
Query:

FROM msdyncrm_marketingemail
SELECT [Total Newsletters 2]
ORDER BY [Total Newsletters 2] DESC

Total Events
Visual: Card
Query:

FROM msevtmgt_Event
SELECT [Total EVents]
ORDER BY [Total EVents] DESC

Total Event Registrations
Visual: Card
Query:

FROM msevtmgt_EventRegistration
SELECT [Total Event Registrations]
ORDER BY [Total Event Registrations] DESC

Total Customer Voice
Visual: Card
Query:

FROM msfp_surveyresponse
SELECT [Total Customer Voice]
ORDER BY [Total Customer Voice] DESC

Total Subscribers
Visual: Card
Query:

FROM ListMember
SELECT [Total Subscribers]
ORDER BY [Total Subscribers] DESC

Average Subscriptions per Contact
Visual: Card
Query:

FROM ListMember
SELECT [Average Subscriptions per Contact]
ORDER BY [Average Subscriptions per Contact] DESC

Date slicer
Visual: Slicer
Query:

FROM DateTable
SELECT [Date]
ORDER BY [Date] ASC
4) Page 1

This looks like a summary dashboard that reuses visuals from the other pages.

Customer Journeys

FROM msdyncrm_customerjourney
SELECT COUNTNONNULL([TotalJourneys])

Marketing Pages

FROM msdyncrm_marketingpage
SELECT COUNTNONNULL([Total Marketing Pages])

Marketing Emails

FROM msdyncrm_marketingemail
SELECT COUNTNONNULL([Total Marketing EMails])

Marketing Forms

FROM msdyncrm_marketingform
SELECT COUNTNONNULL([Total Marketing Forms])

Total Newsletters

FROM msdyncrm_marketingemail
SELECT [Total Newsletters 2]

Total Events

FROM msevtmgt_Event
SELECT [Total EVents]

Total Event Registrations

FROM msevtmgt_EventRegistration
SELECT [Total Event Registrations]

Total Customer Voice

FROM msfp_surveyresponse
SELECT [Total Customer Voice]

Total Subscribers

FROM ListMember
SELECT [Total Subscribers]

Average Subscriptions per Contact

FROM ListMember
SELECT [Average Subscriptions per Contact]

Date slicer

FROM DateTable
SELECT [Date]
ORDER BY [Date] ASC

Total Accounts Added

FROM Account
SELECT [Total Accounts]

Total Contacts Added

FROM Contact
SELECT [Total Contacts]

Consent Given

FROM ConsentTable
SELECT SUM([ConsentGivenNumeric]), [ConsentType]
GROUP BY [ConsentType]

Total Projects

FROM cap_project
SELECT [Total Projects]

Total Users

FROM cap_project
SELECT [Total Users]

Onboarding Project Users

FROM cap_esacontactonboarding
SELECT [Users Associated to an Onboarding Project]

Number of Projects with Users

FROM cap_esacontactonboarding
SELECT [Unique Onboarding Projects with Users]

Users Per Project by Project Name

FROM cap_project
SELECT [Users Per Project], [cap_name]
GROUP BY [cap_name]

Onboarding Projects

FROM cap_esacontactonboarding
SELECT [cap_name], [Users Associated to an Onboarding Project]
ORDER BY [cap_name]