SELECT
CAST( SERVERPROPERTY( 'MachineName' ) AS varchar( 30 ) ) AS MachineName ,
CAST( SERVERPROPERTY( 'InstanceName' ) AS varchar( 30 ) ) AS Instance ,
CAST( SERVERPROPERTY( 'ProductVersion' ) AS varchar( 30 ) ) AS ProductVersion ,
CAST( SERVERPROPERTY( 'ProductLevel' ) AS varchar( 30 ) ) AS ProductLevel ,
CAST( SERVERPROPERTY( 'Edition' ) AS varchar( 30 ) ) AS Edition ,
( CASE SERVERPROPERTY( 'EngineEdition')
WHEN 1 THEN 'Personal or Desktop'
WHEN 2 THEN 'Standard'
WHEN 3 THEN 'Enterprise'
END ) AS EngineType ,
CAST( SERVERPROPERTY( 'LicenseType' ) AS varchar( 30 ) ) AS LicenseType ,
SERVERPROPERTY( 'NumLicenses' ) AS #Licenses;
 