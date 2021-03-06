CREATE TABLE #SecuritySettings
    (SiteName nvarchar(MAX),
     KeyName nvarchar(MAX),
     KeyValue nvarchar(MAX),
	 RecommendedValue nvarchar(MAX),
     FromGlobal nvarchar(MAX)
    );
-- Get current version of Kentico
declare @version int = (select CAST(SUBSTRING(KeyValue,0,charindex('.',KeyValue,0)) AS INT) from CMS_SettingsKey where KeyName = 'CMSDBVersion')

-- Get All settings (site/global)
INSERT INTO #SecuritySettings
			SELECT SiteName, KeyName, KeyValue, NULL, 'No'
				FROM CMS_SettingsKey LEFT JOIN CMS_Site ON 
				(CMS_SettingsKey.SiteID = CMS_Site.SiteID)
				WHERE KeyValue IS NOT NULL AND SiteName IS NOT NULL

INSERT INTO #SecuritySettings 
			SELECT SiteName, KeyName, GlobalSettings.KeyValue, NULL, 'Yes'
				FROM CMS_Site, CMS_SettingsKey as GlobalSettings
				WHERE GlobalSettings.SiteID IS NULL
				AND NOT EXISTS 
					(SELECT KeyValue FROM CMS_SettingsKey as SiteSettings WHERE SiteSettings.KeyName = GlobalSettings.KeyName AND SiteSettings.SiteID IS NOT NULL)
				OR EXISTS
					(SELECT KeyValue FROM CMS_SettingsKey as SiteSettings WHERE SiteSettings.KeyName = GlobalSettings.KeyName AND SiteSettings.KeyValue IS NULL AND SiteSettings.SiteID IS NOT NULL)

-- Keep only relevant settings, which match the POI according to Kentico security audit
DELETE FROM #SecuritySettings
WHERE KeyName NOT IN (	-- Security & Membership
						'CMSRegistrationEmailConfirmation', 
						-- Security & Membership -> Passwords
						'CMSPasswordFormat', 
						'CMSResetPasswordRequiresApproval',
						'CMSResetPasswordInterval',
						'CMSPasswordExpiration',
						'CMSPasswordExpirationBehaviour',
						'CMSUsePasswordPolicy',
						'CMSPolicyMinimalLength',
						'CMSPolicyNumberOfNonAlphaNumChars',
						-- Security & Membership -> Protection
						'CMSCaptchaControl',
						'CMSMaximumInvalidLogonAttempts',
						'CMSAutocompleteEnableForLogin',
						-- Content -> Media
						'CMSMediaFileAllowedExtensions',
						-- System -> Files
						'CMSUploadExtensions',
						-- Community -> Forums
						'CMSForumAttachmentExtensions',
						-- Integration -> Rest
						'CMSRESTServiceEnabled',
						'CMSRESTAuthenticationType'
					 )

-- Set recommended values
UPDATE #SecuritySettings SET RecommendedValue = 'True' 
WHERE KeyName IN (
					'CMSRegistrationEmailConfirmation',		
					'CMSResetPasswordRequiresApproval',	
					'CMSSendEmailWithResetPassword',
					'CMSPasswordExpiration',	
					'CMSUsePasswordPolicy'
				 )

UPDATE #SecuritySettings SET RecommendedValue = CASE WHEN @version<10 THEN 'SHA2SALT' ELSE 'PBKDF2' END WHERE KeyName = 'CMSPasswordFormat'
UPDATE #SecuritySettings SET RecommendedValue = 12 WHERE KeyName = 'CMSResetPasswordInterval' -- maximum
UPDATE #SecuritySettings SET RecommendedValue = 'LOCKACCOUNT' WHERE KeyName = 'CMSPasswordExpirationBehaviour'
UPDATE #SecuritySettings SET RecommendedValue = 8 WHERE KeyName = 'CMSPolicyMinimalLength'
UPDATE #SecuritySettings SET RecommendedValue = 2 WHERE KeyName = 'CMSPolicyNumberOfNonAlphaNumChars'
UPDATE #SecuritySettings SET RecommendedValue = 3 WHERE KeyName = 'CMSCaptchaControl' -- 3 is reCaptcha
UPDATE #SecuritySettings SET RecommendedValue = 5 WHERE KeyName = 'CMSMaximumInvalidLogonAttempts'
UPDATE #SecuritySettings SET RecommendedValue = 'False' WHERE KeyName = 'CMSAutocompleteEnableForLogin'
			
UPDATE #SecuritySettings SET RecommendedValue = 'Check for possible dangerous extensions (.exe, .src, ...)' WHERE KeyName = 'CMSMediaFileAllowedExtensions'
UPDATE #SecuritySettings SET RecommendedValue = 'Check for possible dangerous extensions (.exe, .src, ...)' WHERE KeyName = 'CMSUploadExtensions'
UPDATE #SecuritySettings SET RecommendedValue = 'Check for possible dangerous extensions (.exe, .src, ...)' WHERE KeyName = 'CMSForumAttachmentExtensions'
UPDATE #SecuritySettings SET RecommendedValue = 'There are known security flaws in REST. Check the settings, in case REST is enabled.' WHERE KeyName = 'CMSRESTServiceEnabled'

-- Include only settings with values not set according to recommended values. 
-- Note: Integer values (maximum/minimum) are verified in code. Allowed extensions and REST settings are included always and need to be checked manually. 
SELECT SiteName as 'Site name', KeyName as 'Key name', KeyValue as 'Key value', RecommendedValue as 'Recommended value', FromGlobal as 'Inherited from global' 
FROM #SecuritySettings 
WHERE RecommendedValue <> KeyValue
ORDER BY SiteName, KeyName

DROP TABLE #SecuritySettings