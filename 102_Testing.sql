USE SampleWarehouse
GO

--TRUNCATE TABLE [datamart].[marks]
--TRUNCATE TABLE [audit].[marks]
--TRUNCATE TABLE [audit].[SSISlog]
--TRUNCATE TABLE [datamart].[teams]
--GO

SELECT * FROM [datamart].[marks] order by id desc
SELECT * FROM [datamart].[teams] order by [teams_id]
SELECT * FROM [audit].[marks]
SELECT * FROM [audit].[SSISlog] order by id
GO


--DELETE [audit].[SSISlog] WHERE [step_ref] LIKE '5.%'
--INSERT INTO [audit].[SSISlog] ([step_ref], [step_desc]) VALUES (5.1,?);
--SELECT [roll_number], [marks] FROM [datamart].[marks]

--INSERT INTO [audit].[SSISlog] ([step_ref], [step_desc], [records_affected]) 
--VALUES 
--	('5.1','',?),
--	('5.2','',?);

--UPDATE [datamart].[marks] SET [marks] = 88 WHERE [roll_number] = '1234'
--SELECT @@ROWCOUNT as RecordsUpdated;

