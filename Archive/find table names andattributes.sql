SELECT logicalname
FROM metadata.entity
WHERE logicalname LIKE '%listmember%'





SELECT entitylogicalname,logicalname 
FROM metadata.attribute
WHERE entitylogicalname LIKE '%msdyncrm_marketingemail%'
order by logicalname


SELECT entitylogicalname,logicalname 
FROM metadata.attribute
WHERE logicalname LIKE '%sent%'


WHERE entitylogicalname = 'msdynmkt_contactpointconsent4'
order by logicalname


select count(*) 
select top 10 * from cap_cap_project_systemuser