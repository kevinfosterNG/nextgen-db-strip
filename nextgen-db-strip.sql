/****************************************************************
This will delete all but 10 patients from the system. 
It will remove anything that is not directly related to the patients.
to run this against a database.  do a find and replace all for 
[targetDB] and replace it will your target database to be stripped
-- NextGen Database Strip Utility
-- Author:  Kevin Foster
-- Created: Oct 14, 2009 
****************************************************************/
--CONFIGURE INDEX UPDATE
DECLARE @index_update CHAR(1) = 'N'
--CONFIGURE THE ANONYMIZE&STRIP (Y = do both, N = only anonymize)
DECLARE @anon_and_strip CHAR(1) = 'N'
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
	SELECT '['+ SCHEMA_NAME(schema_id) + '].[' + st.name + ']'
	FROM sys.tables st
	WHERE st.name like '%bak%' OR st.name like '%bkup%' OR st.name like '%backkup_%'
	ORDER BY 1

	OPEN dbTable
	FETCH next FROM dbTable INTO @table

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @verbose > 1 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Dropping backup table: '+@table
		SELECT @sql = 'DROP TABLE '+@table
		IF @verbose > 2 PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') '+@sql
		EXEC (@sql)
	FETCH next FROM dbTable INTO @table
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
	UPDATE person SET image_id=NULL WHERE image_id IS NULL

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
		PRINT '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Patient specific information'
		PRINT '======================================================'
	END

	/*Cleanup tables containing person data*/
	DECLARE cur CURSOR FOR
	SELECT so.name, sc.name FROM sysobjects so INNER JOIN syscolumns sc ON so.id=sc.id
	WHERE sc.name IN ('person_id','pt_id') and so.name !='nxmd_xml_data_enterp_cnfg' and so.name !='_DOHC_persons_to_keep' and so.xtype!='V' AND sc.length>=16
	ORDER BY 1

	OPEN cur
	FETCH next FROM cur INTO @table, @col

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @verbose > 1 print '('+CONVERT(VARCHAR(50),GETDATE(),121)+') Stripping table: '+@table
		--extract desired data prior to truncate
		SELECT @sql='SELECT * INTO '+@table+@bak_suffix+' FROM '+@table+' WHERE '+@col+' IN (SELECT person_id FROM [_DOHC_Persons_to_Keep] (nolock))'		--add condition here
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
		SELECT @sql='SELECT * INTO '+@table+@bak_suffix+' FROM '+@table+' WHERE claim_ID IN (SELECT claim_ID FROM claims (nolock))'		--add condition here
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
		SELECT @sql='SELECT * INTO '+@table+@bak_suffix+' FROM '+@table+' WHERE '+@col+' IN (SELECT enc_ID FROM ..[patient_encounter] (nolock))'		--add condition here
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
		SELECT @sql='SELECT * INTO '+@table+@bak_suffix+' FROM '+@table+' WHERE trans_ID IN (SELECT trans_ID FROM transactions (nolock))'		--add condition here
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