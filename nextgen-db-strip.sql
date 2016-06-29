/****************************************************************
This will delete all but 10 patients from the system. 
It will remove anything that is not directly related to the patients.
to run this against a database.  
-- NextGen Database Strip Utility
-- Author:  Kevin Foster
-- Created: Oct 14, 2009

10.14.09 Created wrapper around Simon's script to anonymize
  and then strip out all patients that aren't anonymized.  
  This would allow a much smaller database. 

1.21.10 Modifed the sig_event and image table handling to
  truncate instead of delete all lines.  Speed increase gained
  Also added some conditions to initialization process to 
  prevent target database and selected database from being 
  different.  Also added conditions to not allow prod to
  accidentally be stripped.

10.12.11 Several new enhancements to the strip process:  
  1) Multiple occurrences of log file dumping occur during the
  strip to keep the NextGen_Log physical file small.
  2) Cleaned up error messages having to do with view/function 
  deletes that could not be performed, so those tables are 
  excluded from the strip process.
  3) Cleaned up error messages for the encID/enc_id column to 
  intelligently determine which delete command to use.  
  4) Added section in the beginning to dump any backup tables 
  (ie. tables that had been copied by nextgen for support issues)
  5)  Added explicit database names to the dynamic sql to allow
  for the script to be configured as a sql job.

10.06.12 Performance enhancements:
  1) Logic for disabling database triggers added prior to data 
  stripping section to minimize the data I/O to execute the 
  deletions.

10.09.12 Code Refactor:
  1) Optimizations required for overall performance of the 
  query.  Code utilizes a method of exporting the desired 
  data into a new table, truncating the existing table, then
  inserting the desired data back into the original table.
  2) verbose variable added to include as much or as little 
  of the message log data.  Default is 1 which shows each 
  table being modified as it happens.

01.25.13 Testing and tuning
  1) modified the db shrink step to use the shrinkfile 
  command instead of the shrinkdatabase.  
  2) removed NextGen_Log dumping because of error with full 
  database recovery no longer supporting it.

06.05.13 Formatting and bug fixing
  1) Moved configuration setting @verbose to the top of the
  script.
  2) Combined @verbose conditional printing into BEGIN/END
  statements.
  3) Found that ICS tables and EPM truncation commands were
  not assigned to exec the dynamic sql.  Added code to do so.
  4) Added additional @verbose logging for some dynamic SQL 
  commands that would not print out when desired.
  5) Standardized all dynamic sql commands to use @sql variable.
  6) Added additional @verbose setting for step output.
  
09.03.13 Index procedure parameterization and bug fix
  1) Added config option for calling NextGen's custom index 
  update stored proc.
  2) Changed backup table drop process to account for non-dbo 
  owned tables to be dropped and not error out.
  
04.07.14 Parameterization
  1) Added parameter to allow script to be used to anonymize 
  patient data only and skip the data strip step.  
****************************************************************/
--CONFIGURE INDEX UPDATE
DECLARE @index_update CHAR(1) = 'N'
--CONFIGURE THE ANONYMIZE&STRIP (Y = do both, N = only anonymize)
DECLARE @anon_and_strip CHAR(1) = 'Y'
--CONFIGURE VERBOSE LOGGING
DECLARE @verbose INT = 1
/****************************************************************
How much needs to show up in the message output?
	0 = nothing
	1 = minimal headings
	2 = heading + step details
	3 = dynamic SQL generated for execution
****************************************************************/

DECLARE @prac_id varchar(5)
DECLARE @table VARCHAR(100)
DECLARE @schema_owner VARCHAR(100)
DECLARE @col VARCHAR(12)
DECLARE @bak_suffix VARCHAR(25)= '_appdev_strip_bak'
DECLARE @sql VARCHAR(MAX)
DECLARE @dynamic_columns VARCHAR(MAX)

IF @verbose > 0 
BEGIN
	PRINT '======================================================'
	PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Starting DB strip process.'
	PRINT '======================================================'
END

-- NextGen Patient Anonymizer
-- Author: Simon Holzman for DOHC
-- Created: 09/02/2008
SET NOCOUNT ON

/****** Object:  Table [dbo].[_DOHC_Persons_to_Keep]    Script Date: 03/04/2009 14:40:03 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[_DOHC_Persons_to_Keep]') AND type in (N'U'))
	DROP TABLE [dbo].[_DOHC_Persons_to_Keep]

CREATE TABLE _DOHC_Persons_to_Keep
(
	Person_ID	UNIQUEIDENTIFIER,
	Last_Name	VARCHAR(60),
	First_Name	VARCHAR(60),
	SSN		VARCHAR(9),
	Address1	VARCHAR(55),
	Phone		VARCHAR(7),
	Sex		CHAR(1),
	Encounters	INTEGER
)

IF @verbose > 0 
BEGIN
	PRINT '======================================================'
	PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Anonymizing Patients'
	PRINT '======================================================'
END

CREATE UNIQUE CLUSTERED INDEX [inx1] ON [dbo].[_DOHC_Persons_to_Keep] 
(
	[Person_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

/* Begin loop here for practice table.  keep 10 patients per practice */
DECLARE pracTable CURSOR FOR
SELECT practice_id FROM practice ORDER BY 1
	
OPEN pracTable
FETCH next FROM pracTable INTO @prac_id

WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO _DOHC_Persons_to_Keep
	SELECT TOP 1 Person_ID,'TesttA','NewbornMale','111220001','111 Test Street','2220001','M', COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth > '20080821' AND Sex = 'M' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep
	SELECT TOP 1 Person_ID,'TesttB','NewbornFemale','111220002','222 Test Street','2220002','F',COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth > '20080821' AND Sex = 'F' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep
	SELECT TOP 1 Person_ID,'TesttC','InfantMale','111220003','333 Test Street','2220003','M',COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth BETWEEN '20061101' AND '20080831' AND Sex = 'M' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep
	SELECT TOP 1 Person_ID,'TesttD','InfantFemale','111220004','444 Test Street','2220004','F',COUNT(*)	FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth BETWEEN '20061101' AND '20080831' AND Sex = 'F' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep 
	SELECT TOP 1 Person_ID,'TesttE','ChildMale','111220005','555 Test Street','2220005','M',COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth BETWEEN '19931101' AND '20030815' AND Sex = 'M' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep
	SELECT TOP 1 Person_ID,'TesttF','ChildFemale','111220006','666 Test Street','2220006','F',COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth BETWEEN '19931101' AND '20030815' AND Sex = 'F' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep
	SELECT TOP 1 Person_ID,'TesttG','HighSchMale','111220007','777 Test Street','2220007','M',COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth BETWEEN '19911101' AND '19930815' AND Sex = 'M' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep
	SELECT TOP 1 Person_ID,'TesttH','HighSchFemale','111220008','888 Test Street','2220008','F',COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth BETWEEN '19911101' AND '19930815' AND Sex = 'F' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep
	SELECT TOP 1 Person_ID,'TesttX','AdultMale','111220009','999 Test Street','2220009','M',COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth BETWEEN '19441101' AND '19900815' AND Sex = 'M' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep 
	SELECT TOP 1 Person_ID,'TesttX','AdultFemale','111220010','101010 Test Street','2220010','F',COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth BETWEEN '19441101' AND '19900815' AND Sex = 'F' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep  
	SELECT TOP 1 Person_ID,'TesttY','ElderlyMale','111220011','111111 Test Street','2220011','M',COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth BETWEEN '19081101' AND '19431101' AND Sex = 'M' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC
	
	INSERT INTO _DOHC_Persons_to_Keep 
	SELECT TOP 1 Person_ID,'TesttZ','ElderlyFemale','111220012','121212 Test Street','2220012','F',COUNT(*) FROM Patient_Encounter (nolock) WHERE Person_ID IN (SELECT Person_ID FROM Person (nolock) WHERE Date_of_Birth BETWEEN '19081101' AND '19431101' AND Sex = 'F' AND practice_id=@prac_id) GROUP BY Person_ID ORDER BY 8 DESC

--END PRACTICE LOOP
FETCH next FROM pracTable INTO @prac_id
END
CLOSE pracTable
DEALLOCATE pracTable

-- Update all references to these patients to use the Anonymized information
UPDATE Person SET Last_Name = b.Last_Name, First_Name = b.First_Name, SSN = b.SSN, Address_Line_1 = b.Address1, Home_Phone = '111' + b.Phone, Day_Phone = '222' + b.Phone, Alt_Phone = '333' + b.Phone,  email_address = 'Test@Test.Com', Sex = b.Sex FROM Person a INNER JOIN _DOHC_Persons_to_Keep b ON a.Person_ID = b.Person_ID

-- Used for Emergency Contact in EPM System
UPDATE Patient SET User_Defined1 = 'Shirley ' + b.Last_Name, User_Defined2 = '444 ' + b.Phone, User_Defined3 = 'CA X' + b.Phone FROM Patient a INNER JOIN _DOHC_Persons_to_Keep b ON a.Person_ID = b.Person_ID

UPDATE Patient_ SET full_name = b.First_Name + ' ' + b.Last_Name FROM Patient_ a INNER JOIN _DOHC_Persons_to_Keep b ON a.Person_ID = b.Person_ID

UPDATE Appointments SET Last_Name = b.Last_Name, First_Name = b.First_Name, Description = b.Last_Name + ', ' + b.First_Name, Address_Line_1 = b.Address1, Work_Phone = '222' + b.Phone, Home_Phone = '111' + b.Phone FROM Appointments a INNER JOIN _DOHC_Persons_to_Keep b ON a.Person_ID = b.Person_ID

UPDATE Doc_Queue_Final SET Last_Name = b.Last_Name, First_Name = b.First_Name FROM Doc_Queue_Final a INNER JOIN _DOHC_Persons_to_Keep b ON a.Person_ID = b.Person_ID

UPDATE Lab_Results_P SET Last_Name = UPPER(b.Last_Name), First_Name = UPPER(b.First_Name), Alt_Patient_ID = b.SSN, Sex = b.Sex, Address_Line_1 = b.Address1, Work_Phone = '222' + b.Phone, Home_Phone = '111' + b.Phone FROM Lab_Results_P a INNER JOIN _DOHC_Persons_to_Keep b ON a.Person_ID = b.Person_ID

UPDATE DSC_Master_ SET full_name = b.First_Name + ' ' + b.Last_Name FROM DSC_Master_ a INNER JOIN _DOHC_Persons_to_Keep b ON a.Person_ID = b.Person_ID

UPDATE Pat_Apt_Hist SET Appt_Subject = b.Last_Name + ', ' + b.First_Name FROM Pat_Apt_Hist a INNER JOIN _DOHC_Persons_to_Keep b ON a.Person_ID = b.Person_ID

UPDATE Claims SET Patient_Last_Name = b.Last_Name, Patient_First_Name = b.First_Name, Patient_Sex = b.Sex, Patient_Address_Line_1 = b.Address1, Patient_Phone = '111' + b.Phone, Resp_Party_Last_Name = 'Bloggs', Resp_Party_First_Name = 'Joseph', Resp_Party_Address_Line_1 = '12345 HighTest St'  FROM Claims a INNER JOIN _DOHC_Persons_to_Keep b ON a.Person_ID = b.Person_ID

-- Add the regular Test Patients into the _DOHC_Persons_to_Keep table
INSERT INTO _DOHC_Persons_to_Keep
SELECT Person_ID,Last_Name,First_Name,'','','','',0 FROM Person (nolock) WHERE Last_Name LIKE 'Testt%' /*and SSN !=''*/ AND Person_ID NOT IN (SELECT Person_ID FROM _DOHC_Persons_to_Keep (nolock))

-- Disable ALL members not in the _DOHC_Persons_to_Keep table
UPDATE Person SET Expired_Ind = 'Y', Expired_Date = '22000101' WHERE Person_ID NOT IN (SELECT Person_ID FROM _DOHC_Persons_to_Keep (nolock)) AND ISNULL(Expired_Ind, 'N') = 'N'

IF @verbose > 0 
BEGIN
	PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
	PRINT '======================================================'
	PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Patient anonymization complete.'+CHAR(10)
	PRINT '======================================================'
END
IF @anon_and_strip = 'N'
BEGIN
	PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') No data stripping perfomed.'+CHAR(10)
	PRINT '======================================================'
END
ELSE	
BEGIN

	IF @verbose > 0
	BEGIN	
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Temp Backup Table Cleanup'
		PRINT '======================================================'
	END	

	/*Drop table copy backups (ex. table_bak_DATE)*/
	DECLARE dbTable CURSOR FOR
	SELECT s.name, o.name
	FROM sys.tables t
	INNER JOIN sys.schemas s ON t.schema_id=s.schema_id
	INNER JOIN sys.objects o ON t.name=o.name
	INNER join sys.partitions p on p.object_id = o.object_id
	INNER join sys.allocation_units a on p.partition_id = a.container_id
	WHERE o.type = 'U' AND t.create_date < getdate()-90
	--INCLUDE TABLES:
	AND (t.name like '%bak%' OR t.name LIKE '%bkp%' OR t.name LIKE '%backup%' OR t.name like '%bkup%' OR t.name like '%[_]old' OR ISNUMERIC(RIGHT(t.name, 4))=1)
	--EXCLUDE TABLES:
	AND (t.name NOT LIKE 'ndc_reuse_statistics%')
	AND o.name NOT IN (SELECT table_name FROM ng_indexes)
	GROUP BY s.name, t.name, o.name, t.create_date, t.modify_date
	ORDER BY s.name, t.name

	OPEN dbTable
	FETCH next FROM dbTable INTO @schema_owner, @table

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @verbose > 1 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Dropping backup table: '+@table
		SELECT @sql = 'DROP TABLE ['+@schema_owner+'].['+@table+']'
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)
	FETCH next FROM dbTable INTO @schema_owner, @table
	END
	CLOSE dbtable
	DEALLOCATE dbTable

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Disable Database Triggers'
		PRINT '======================================================'
	END

	DECLARE @tableName NVARCHAR(500)
	DECLARE cur CURSOR FOR 
	SELECT name AS tbname FROM sysobjects WHERE id IN(SELECT parent_obj FROM sysobjects WHERE xtype='tr')
	OPEN cur
	FETCH next FROM cur INTO @tableName
	WHILE @@fetch_status = 0
	BEGIN
		SET @sql ='ALTER TABLE '+ @tableName + ' DISABLE TRIGGER ALL'
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)
		FETCH next FROM cur INTO @tableName
	END
	CLOSE cur
	DEALLOCATE cur

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
	/*----------------------------------------------------------------------------------------------------------
	Begin majority strip.
	----------------------------------------------------------------------------------------------------------*/
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Image specific information'
		PRINT '======================================================'
	END

	TRUNCATE TABLE images
	--remove patient image references
	WHILE 1=1
	BEGIN
		UPDATE TOP(1000) person SET image_id=NULL
		WHERE image_id IS NOT NULL
	
		IF @@ROWCOUNT=0 
			BREAK
	END

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Sig event specific information'
		PRINT '======================================================'
	END

	TRUNCATE TABLE sig_events

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Ancillary product configuration'
		PRINT '======================================================'
	END
	----------------------------------
	--Per NextGen Article #000021617--
	----------------------------------
	--ePrescribing
	TRUNCATE TABLE surescripts_config
	DELETE FROM configuration_options WHERE app_name LIKE '%ePrescribing%'
	--Patient Portal
	TRUNCATE TABLE ngweb_account_settings
	TRUNCATE TABLE ngweb_appointment_req
	TRUNCATE TABLE ngweb_communications
	TRUNCATE TABLE ngweb_enrollments
	TRUNCATE TABLE ngweb_evaluation_req
	TRUNCATE TABLE ngweb_grant
	TRUNCATE TABLE ngweb_imh_question_series
	TRUNCATE TABLE ngweb_imh_question_state
	TRUNCATE TABLE ngweb_msg_sub_categories
	TRUNCATE TABLE ngweb_online_identities
	TRUNCATE TABLE ngweb_pat_alt_pharm
	TRUNCATE TABLE ngweb_payment_prv_config
	TRUNCATE TABLE ngweb_rout_tree
	TRUNCATE TABLE NGWEB_STATEMENT_PAYMENT
	TRUNCATE TABLE nxmd_enrollment_xref
	TRUNCATE TABLE nxmd_enterp_practice_xref
	TRUNCATE TABLE nxmd_export
	TRUNCATE TABLE nxmd_import
	TRUNCATE TABLE nxmd_loc_systemxref
	TRUNCATE TABLE nxmd_med_renewals
	TRUNCATE TABLE nxmd_medication_request_log
	TRUNCATE TABLE nxmd_message_reject
	TRUNCATE TABLE nxmd_onetime_profile
	TRUNCATE TABLE nxmd_pat_systemxref
	TRUNCATE TABLE nxmd_pat_template_import
	TRUNCATE TABLE nxmd_person_policy
	TRUNCATE TABLE nxmd_prv_systemxref
	TRUNCATE TABLE nxmd_template_export_policy
	TRUNCATE TABLE nxmd_template_set_assignments
	TRUNCATE TABLE nxmd_template_sets
	TRUNCATE TABLE nxmd_practice_systemxref
	TRUNCATE TABLE ngweb_appointment_resp
	TRUNCATE TABLE ngweb_comm_attach_xref
	TRUNCATE TABLE ngweb_comm_recpts
	TRUNCATE TABLE ngweb_routing_list
	TRUNCATE TABLE ngweb_account
	TRUNCATE TABLE ngweb_person
	TRUNCATE TABLE ngweb_person_address
	TRUNCATE TABLE ngweb_phone_number
	TRUNCATE TABLE ngweb_email_address
	TRUNCATE TABLE nxmd_location
	TRUNCATE TABLE nxmd_template_set_data
	TRUNCATE TABLE nxmd_template_set_members
	TRUNCATE TABLE nxmd_practice_systemxref
	TRUNCATE TABLE nxmd_practice_web_settings
	TRUNCATE TABLE nxmd_practice_web_text
	TRUNCATE TABLE nxmd_practices
	TRUNCATE TABLE nxmd_systems
	TRUNCATE TABLE nxmd_enterp_practice_xref
	TRUNCATE TABLE nxmd_enterprise
	TRUNCATE TABLE nxmd_enterprise_system_xref
	TRUNCATE TABLE nxmd_export_capture
	--Formularies
	TRUNCATE TABLE ng_rxh_altformu_med_data
	TRUNCATE TABLE ng_rxh_copay_drug_specific
	TRUNCATE TABLE ng_rxh_copay_summary
	TRUNCATE TABLE ng_rxh_coverage_data
	TRUNCATE TABLE ng_rxh_coverage_mstr
	TRUNCATE TABLE ng_rxh_coverage_qty_limit
	TRUNCATE TABLE ng_rxh_coverage_qty_limits
	TRUNCATE TABLE ng_rxh_coverage_res_links
	TRUNCATE TABLE ng_rxh_coverage_step_data
	TRUNCATE TABLE ng_rxh_formulary_med_data
	TRUNCATE TABLE ng_rxh_formulary_med_data_UPD
	TRUNCATE TABLE ng_rxh_formulary_mstr

	--Fix nagging PDR date error on med module
	INSERT INTO surescripts_config (config_id, config_value, created_by, modified_by, create_timestamp, modify_timestamp)
	VALUES ('PDR_LAST_FILE_DATE_TIME', GETDATE()+999, 0,0,GETDATE(),GETDATE())

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Patient specific information'
		PRINT '======================================================'
	END

	/*Cleanup tables containing person data*/
	DECLARE cur CURSOR FOR
	SELECT so.name, sc.name FROM sysobjects so INNER JOIN syscolumns sc ON so.id=sc.id
	WHERE sc.name IN ('person_id','pt_id') and so.name !='nxmd_xml_data_enterp_cnfg' and so.name !='_DOHC_persons_to_keep' and so.xtype!='V' AND sc.length>=16  and so.type='U'
	ORDER BY 1

	OPEN cur
	FETCH next FROM cur INTO @table, @col

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @verbose > 1 print '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Stripping table: '+@table
		--extract desired data prior to truncate
		SELECT @sql='SELECT * INTO '+@table+@bak_suffix+' FROM '+@table+' WHERE '+@col+' IN (SELECT person_id FROM [_DOHC_Persons_to_Keep] (nolock))'
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)
		
		--truncate table
		SELECT @sql='TRUNCATE TABLE '+@table
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		SELECT @dynamic_columns = COALESCE(@dynamic_columns + ', ', '') + sc.name
		FROM sys.tables st
		INNER JOIN sys.columns sc ON st.object_id=sc.object_id
		WHERE st.name=@table
		AND sc.name!='row_timestamp'
		AND sc.is_computed=0

		--add back data from backup table
		SELECT @sql='INSERT INTO '+@table+' ('+@dynamic_columns+') '+CHAR(10)+'SELECT ' + @dynamic_columns + CHAR(10)+'FROM '+@table+@bak_suffix

		--error checking for tables with an identity column
		IF EXISTS (SELECT 1 FROM sys.tables st INNER JOIN sys.columns sc ON st.object_id=sc.object_id WHERE st.name=@table AND sc.is_identity=1)
			SELECT @sql='SET IDENTITY_INSERT '+@table+' ON'+CHAR(10)+@sql+CHAR(10)+'SET IDENTITY_INSERT '+@table+' OFF'

		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		--drop backup table
		SELECT @sql='DROP TABLE '+@table+@bak_suffix
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		--reset variables
		SELECT @sql=NULL, @dynamic_columns=NULL

	FETCH next FROM cur INTO @table, @col
	END
	CLOSE cur
	DEALLOCATE cur

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Claims specific information'
		PRINT '======================================================'
	END

	/*Claims table cleanup*/
	DECLARE cur CURSOR FOR
	SELECT name FROM sysobjects WHERE id IN ( SELECT id FROM syscolumns WHERE name = 'claim_id') and name != 'claims'
	ORDER BY name

	OPEN cur
	FETCH next FROM cur INTO @table

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @verbose > 1 print '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Stripping table: '+@table
		--extract desired data prior to truncate
		SELECT @sql='SELECT * INTO '+@table+@bak_suffix+' FROM '+@table+' WHERE claim_ID IN (SELECT claim_ID FROM claims (nolock))'
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)
		
		--truncate table
		SELECT @sql='TRUNCATE TABLE '+@table
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		SELECT @dynamic_columns = COALESCE(@dynamic_columns + ', ', '') + sc.name 
		FROM sys.tables st
		INNER JOIN sys.columns sc ON st.object_id=sc.object_id
		WHERE st.name=@table
		AND sc.name!='row_timestamp'

		--add back data from backup table
		SELECT @sql='INSERT INTO '+@table+' ('+@dynamic_columns+') '+CHAR(10)+'SELECT ' + @dynamic_columns + CHAR(10)+'FROM '+@table+@bak_suffix

		--error checking for tables with an identity column
		IF EXISTS (SELECT 1 FROM sys.tables st INNER JOIN sys.columns sc ON st.object_id=sc.object_id WHERE st.name=@table AND sc.is_identity=1)
			SELECT @sql='SET IDENTITY_INSERT '+@table+' ON'+CHAR(10)+@sql+CHAR(10)+'SET IDENTITY_INSERT '+@table+' OFF'

		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		--drop backup table
		SELECT @sql='DROP TABLE '+@table+@bak_suffix
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		--reset variables
		SELECT @sql=NULL, @dynamic_columns=NULL

	FETCH next FROM cur INTO @table
	END
	CLOSE cur
	DEALLOCATE cur

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Encounter specific information'
		PRINT '======================================================'
	END

	/*Clear encounter information*/
	DECLARE cur CURSOR FOR
	SELECT so.name, sc.name FROM sysobjects so INNER JOIN syscolumns sc ON so.id=sc.id
	WHERE so.id NOT IN (select id FROM syscolumns where name = 'person_id') and so.name NOT IN ('patient_encounter','proctrig_xref') and sc.name IN ('encid','enc_id','enct_id') and so.xtype!='V'
	ORDER BY 1

	OPEN cur
	FETCH next FROM cur INTO @table, @col

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @verbose > 1 print '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Stripping table: '+@table
		--extract desired data prior to truncate
		SELECT @sql='SELECT * INTO '+@table+@bak_suffix+' FROM '+@table+' WHERE '+@col+' IN (SELECT enc_ID FROM ..[patient_encounter] (nolock))'
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)
		
		--truncate table
		SELECT @sql='TRUNCATE TABLE '+@table
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		SELECT @dynamic_columns = COALESCE(@dynamic_columns + ', ', '') + sc.name
		FROM sys.tables st
		INNER JOIN sys.columns sc ON st.object_id=sc.object_id
		WHERE st.name=@table
		AND sc.name!='row_timestamp'

		--add back data from backup table
		SELECT @sql='INSERT INTO '+@table+' ('+@dynamic_columns+') '+CHAR(10)+'SELECT ' + @dynamic_columns + CHAR(10)+'FROM '+@table+@bak_suffix

		--error checking for tables with an identity column
		IF EXISTS (SELECT 1 FROM sys.tables st INNER JOIN sys.columns sc ON st.object_id=sc.object_id WHERE st.name=@table AND sc.is_identity=1)
			SELECT @sql='SET IDENTITY_INSERT '+@table+' ON'+CHAR(10)+@sql+CHAR(10)+'SET IDENTITY_INSERT '+@table+' OFF'

		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		--drop backup table
		SELECT @sql='DROP TABLE '+@table+@bak_suffix
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		--reset variables
		SELECT @sql=NULL, @dynamic_columns=NULL

	FETCH next FROM cur INTO @table, @col
	END
	CLOSE cur
	DEALLOCATE cur

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') ICS tables information'
		PRINT '======================================================'
	END

	SET @table = 'page'
	IF @verbose > 1 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Truncating table: '+@table
	SELECT @sql='TRUNCATE TABLE '+@table
	IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
	EXEC (@sql)

	SET @table = 'document'
	IF @verbose > 1 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Truncating table: '+@table
	SELECT @sql='TRUNCATE TABLE '+@table
	IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
	EXEC (@sql)

	SET @table = 'transfer'
	IF @verbose > 1 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Truncating table: '+@table
	SELECT @sql='TRUNCATE TABLE '+@table
	IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
	EXEC (@sql)
		
	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') EPM misc info'
		PRINT '======================================================'
	END

	SET @table = 'advisor_history'
	IF @verbose > 1 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Truncating table: '+@table
	SELECT @sql='TRUNCATE TABLE '+@table
	IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
	EXEC (@sql)

	SET @table = 'service_item_summary'
	IF @verbose > 1 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Truncating table: '+@table
	SELECT @sql='TRUNCATE TABLE '+@table
	IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
	EXEC (@sql)

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') EPM transaction information'
		PRINT '======================================================'
	END

	/*Clear transaction information*/
	DECLARE cur CURSOR FOR
	SELECT so.name, sc.name FROM sysobjects so INNER JOIN syscolumns sc ON so.id=sc.id
	WHERE sc.name IN('trans_id') and so.name != 'transactions' and so.xtype!='V' and sc.length=16
	ORDER BY 1

	OPEN cur
	FETCH next FROM cur INTO @table, @col

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @verbose > 1 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Stripping table: '+@table

		--extract desired data prior to truncate
		SELECT @sql='SELECT * INTO '+@table+@bak_suffix+' FROM '+@table+' WHERE trans_ID IN (SELECT trans_ID FROM transactions (nolock))'
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)
		
		--truncate table
		SELECT @sql='TRUNCATE TABLE '+@table
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		SELECT @dynamic_columns = COALESCE(@dynamic_columns + ', ', '') + sc.name
		FROM sys.tables st
		INNER JOIN sys.columns sc ON st.object_id=sc.object_id
		WHERE st.name=@table
		AND sc.name!='row_timestamp'

		--add back data from backup table
		SELECT @sql='INSERT INTO '+@table+' ('+@dynamic_columns+') '+CHAR(10)+'SELECT ' + @dynamic_columns + CHAR(10)+'FROM '+@table+@bak_suffix

		--error checking for tables with an identity column
		IF EXISTS (SELECT 1 FROM sys.tables st INNER JOIN sys.columns sc ON st.object_id=sc.object_id WHERE st.name=@table AND sc.is_identity=1)
			SELECT @sql='SET IDENTITY_INSERT '+@table+' ON'+CHAR(10)+@sql+CHAR(10)+'SET IDENTITY_INSERT '+@table+' OFF'

		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		--drop backup table
		SELECT @sql='DROP TABLE '+@table+@bak_suffix
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)

		--reset variables
		SELECT @sql=NULL, @dynamic_columns=NULL
		
	FETCH next FROM cur INTO @table, @col
	END
	CLOSE cur
	DEALLOCATE cur

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') DB Cleanup'
		PRINT '======================================================'
	END
		
	/****** Object:  Table [dbo].[_DOHC_Persons_to_Keep]    Script Date: 03/04/2009 14:40:03 ******/
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[_DOHC_Persons_to_Keep]') AND type in (N'U'))
		DROP TABLE [dbo].[_DOHC_Persons_to_Keep]

	--Clean indexes
	IF @index_update = 'Y'
	BEGIN
		IF @verbose > 0
		BEGIN
			PRINT '======================================================'
			PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Index Checking'
			PRINT '======================================================'
		END
		
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+'''R'',''EI,RO,RC,RN,MP,MC,MN,US25'''
		EXEC ng_check_indexes 'R','EI,RO,RC,RN,MP,MC,MN,US25'

		IF @verbose > 0 
		BEGIN
			PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		END
	END

	IF @verbose > 0 
	BEGIN
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Shrinking database.'
		PRINT '======================================================'
	END
		
	--Reclaim open space
	DECLARE @fname VARCHAR(100)
	DECLARE cur CURSOR FOR
	SELECT name FROM sys.database_files
	ORDER BY file_id

	OPEN cur
	FETCH next FROM cur INTO @fname

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @sql = 'DBCC SHRINKFILE (N'''+@fname+''', 1)'
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)
	FETCH next FROM cur INTO @fname
	END
	CLOSE cur
	DEALLOCATE cur

	IF @verbose > 0 
	BEGIN
	--	DBCC SHOWFILESTATS
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Re-enable Database Triggers'
		PRINT '======================================================'
	END

	DECLARE cur CURSOR FOR 
	SELECT name AS tbname FROM sysobjects WHERE id IN(SELECT parent_obj FROM sysobjects WHERE xtype='tr')
	OPEN cur
	FETCH next FROM cur INTO @tableName
	WHILE @@fetch_status = 0
	BEGIN
		SET @sql ='ALTER TABLE '+ @tableName + ' ENABLE TRIGGER ALL'
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)
		FETCH next FROM cur INTO @tableName
	END
	CLOSE cur
	DEALLOCATE cur

	IF @verbose > 0 
	BEGIN
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Done.'+CHAR(10)
		PRINT '======================================================'
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Database strip process completed.'
		PRINT '======================================================'
	END
END