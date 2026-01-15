USE JOB_PORTAL_DB;
GO

SELECT DISTINCT SL.Login AS  [User Login], SL.Full_Name AS  [User Name], SL.Phone_Number AS  [User Phone] FROM [JOB_PORTAL_DB].[dbo].[Security_Logins] AS  SL 
JOIN [JOB_PORTAL_DB].[dbo].[Security_Logins_Log] AS SLL ON SL.Id = SLL.Login WHERE SLL.Logon_Date < '2017-01-01' 
AND SL.Id NOT IN (SELECT Login FROM [dbo].[Security_Logins_Log] WHERE Logon_Date BETWEEN '2017-01-01'and '2017-12-31')
ORDER BY 'User Login';
	
SELECT DISTINCT CD.Company_Name FROM [JOB_PORTAL_DB].[dbo].[Applicant_Job_Applications]  AS  AJA 
JOIN [JOB_PORTAL_DB].[dbo].[Company_Jobs] AS CJ ON CJ.Id = AJA.Job 
JOIN [JOB_PORTAL_DB].[dbo].[Company_Descriptions] AS CD ON CJ.Company = CD.Company
WHERE CD.LanguageId = 'EN' 
GROUP BY CD.Company_Name Having Count(*) >=10  ORDER BY CD.Company_Name ;

SELECT SL.Full_Name AS [Applicant Name], AP.Current_Salary AS [Current Salary], AP.Currency FROM [JOB_PORTAL_DB].[dbo].[Applicant_Profiles]  AS  AP
JOIN [JOB_PORTAL_DB].[dbo].[Security_Logins] AS SL ON AP.Login = SL.Id
WHERE AP.Current_Salary IN ( SELECT MAX(Current_Salary) FROM  [JOB_PORTAL_DB].[dbo].[Applicant_Profiles] WHERE Currency = AP.Currency GROUP BY Currency)
ORDER BY AP.Currency;

SELECT CD.Company_Name AS [Company Name], COUNT(CJ.Company) AS [#Jobs Posted] FROM [JOB_PORTAL_DB].[dbo].[Company_Profiles] AS CP
JOIN [JOB_PORTAL_DB].[dbo].[Company_Descriptions] CD ON CP.Id = CD.Company AND CD.LanguageID = 'EN'
LEFT JOIN [JOB_PORTAL_DB].[dbo].[Company_Jobs] CJ ON CP.Id = CJ.Company
GROUP BY CD.Company_Name  
ORDER BY [#Jobs Posted];


SELECT 'Clients with Posted Jobs:' AS [Title], COUNT(DISTINCT CP.Id) AS [NNN] FROM [JOB_PORTAL_DB].[dbo].[Company_Profiles] AS CP
JOIN [JOB_PORTAL_DB].[dbo].[Company_Jobs] AS CJ ON CP.Id = CJ.Company
UNION
SELECT 'Clients without Posted Jobs:' AS [Title], COUNT(DISTINCT CP.Id) AS [NNN] FROM [JOB_PORTAL_DB].[dbo].[Company_Profiles] AS CP
LEFT JOIN [JOB_PORTAL_DB].[dbo].[Company_Jobs] AS CJ ON CP.Id = CJ.Company
WHERE CJ.Company IS NULL;