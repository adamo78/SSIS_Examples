--Release
GO
USE [master]
GO

--Create database
GO
CREATE DATABASE [SampleWarehouse]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Sample Warehouse', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Sample Warehouse.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Sample Warehouse_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\Sample Warehouse_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [SampleWarehouse].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [SampleWarehouse] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [SampleWarehouse] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [SampleWarehouse] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [SampleWarehouse] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [SampleWarehouse] SET ARITHABORT OFF 
GO

ALTER DATABASE [SampleWarehouse] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [SampleWarehouse] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [SampleWarehouse] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [SampleWarehouse] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [SampleWarehouse] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [SampleWarehouse] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [SampleWarehouse] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [SampleWarehouse] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [SampleWarehouse] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [SampleWarehouse] SET  DISABLE_BROKER 
GO

ALTER DATABASE [SampleWarehouse] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [SampleWarehouse] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [SampleWarehouse] SET TRUSTWORTHY OFF 
GO

ALTER DATABASE [SampleWarehouse] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [SampleWarehouse] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [SampleWarehouse] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [SampleWarehouse] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [SampleWarehouse] SET RECOVERY FULL 
GO

ALTER DATABASE [SampleWarehouse] SET  MULTI_USER 
GO

ALTER DATABASE [SampleWarehouse] SET PAGE_VERIFY CHECKSUM  
GO

ALTER DATABASE [SampleWarehouse] SET DB_CHAINING OFF 
GO

ALTER DATABASE [SampleWarehouse] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO

ALTER DATABASE [SampleWarehouse] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO

ALTER DATABASE [SampleWarehouse] SET DELAYED_DURABILITY = DISABLED 
GO

ALTER DATABASE [SampleWarehouse] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO

ALTER DATABASE [SampleWarehouse] SET QUERY_STORE = OFF
GO

ALTER DATABASE [SampleWarehouse] SET  READ_WRITE 
GO

USE [SampleWarehouse]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Create schemas
GO
CREATE SCHEMA [datamart]
GO
CREATE SCHEMA [audit]
GO

-- Create data table
GO
CREATE TABLE [datamart].[marks](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[roll_number] [int] NOT NULL,
	[marks] [int] NOT NULL,
	[teams_id] [int] NULL,
	[comments] [varchar](100) NULL,
	[upload_notes] [varchar](100) NULL,
	[created_by] [varchar](50) NOT NULL,
	[created_on] [datetime] NOT NULL,
	[changed_by] [varchar](50) NULL,
	[changed_on] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [datamart].[marks] ADD  CONSTRAINT [DF_datamart_marks_created_by]  DEFAULT (original_login()) FOR [created_by]
GO
ALTER TABLE [datamart].[marks] ADD  CONSTRAINT [DF_datamart_marks_created_on]  DEFAULT (getdate()) FOR [created_on]
GO

-- create audit table
GO
CREATE TABLE [audit].[marks](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[roll_number] [int] NOT NULL,
	[changed_field] [varchar](50) NOT NULL,
	[changed_from] [varchar](100) NULL,
	[changed_to] [varchar](100) NULL,
	[created_by] [varchar](50) NOT NULL,
	[created_on] [datetime] NOT NULL
) ON [PRIMARY]
GO

-- create trigger to populate audit table
GO
CREATE TRIGGER [datamart].[TG_marks_after_update]
ON [datamart].[marks] AFTER UPDATE
AS 

BEGIN
	SET NOCOUNT ON;

	DECLARE @u varchar(50), @d smalldatetime;

	SELECT @u = original_login();
	SELECT @d = getdate();

	UPDATE m
	SET [changed_by] = @u, [changed_on] = @d
	FROM [datamart].[marks] m
	JOIN inserted i ON m.[id] = i.[id];

	INSERT INTO [audit].[marks]
		([roll_number],[changed_field],[changed_from],[changed_to],[created_by],[created_on])
	SELECT 
		i.[roll_number],'marks',d.[marks],i.[marks],@u,@d
	FROM inserted i 
	JOIN deleted d ON i.id = d.id
	WHERE d.[marks] <> i.[marks];

	INSERT INTO [audit].[marks]
		([roll_number],[changed_field],[changed_from],[changed_to],[created_by],[created_on])
	SELECT i.[roll_number],'teams_id',d.[teams_id],i.[teams_id],@u,@d
	FROM inserted i 
	JOIN deleted d ON i.id = d.id
	OR d.[marks] <> i.[marks]
	WHERE d.[comments] <> i.[comments];

	INSERT INTO [audit].[marks]
		([roll_number],[changed_field],[changed_from],[changed_to],[created_by],[created_on])
	SELECT i.[roll_number],'comments',d.[comments],i.[comments],@u,@d
	FROM inserted i 
	JOIN deleted d ON i.id = d.id
	WHERE d.[teams_id] <> i.[teams_id];

	INSERT INTO [audit].[marks]
		([roll_number],[changed_field],[changed_from],[changed_to],[created_by],[created_on])
	SELECT i.[roll_number],'upload_notes',d.[upload_notes],i.[upload_notes],@u,@d
	FROM inserted i 
	JOIN deleted d ON i.id = d.id
	OR d.[marks] <> i.[marks]
	WHERE d.[upload_notes] <> i.[upload_notes];
END
GO
ALTER TABLE [datamart].[marks] ENABLE TRIGGER [TG_marks_after_update]
GO

-- create SSIS log table
GO
CREATE TABLE [audit].[SSISlog](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[step_ref] [varchar](10) NOT NULL,
	[step_desc] [varchar](255) NOT NULL,
	[records_affected] [int] NULL,
	[created_by] [varchar](50) NOT NULL,
	[created_on] [datetime] NOT NULL,
	[changed_by] [varchar](50) NULL,
	[changed_on] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [audit].[SSISlog] ADD  CONSTRAINT [DF_audit_SSISlog_created_by]  DEFAULT (original_login()) FOR [created_by]
GO
ALTER TABLE [audit].[SSISlog] ADD  CONSTRAINT [DF_audit_SSISlog_created_on]  DEFAULT (getdate()) FOR [created_on]
GO

-- create trigger to populate changed by and changed on 
GO
CREATE TRIGGER [audit].[TG_SSISlog_after_update]
ON [audit].[SSISlog] AFTER UPDATE
AS 

BEGIN
	SET NOCOUNT ON;

	DECLARE @u varchar(50), @d smalldatetime;

	SELECT @u = original_login();
	SELECT @d = getdate();

	UPDATE s
	SET [changed_by] = @u, [changed_on] = @d
	FROM [audit].[SSISlog] s
	JOIN inserted i ON s.[id] = i.[id];
END
GO
ALTER TABLE [audit].[SSISlog] ENABLE TRIGGER [TG_SSISlog_after_update]
GO

-- Create teams table
GO
CREATE TABLE [datamart].[teams](
	[teams_id] [int] IDENTITY(1,1) NOT NULL,
	[team_name] [varchar](50) NOT NULL,
) ON [PRIMARY]
GO

-- Create test data for trigger
GO
INSERT INTO [datamart].[marks] ([roll_number], [marks]) VALUES ('111',90)
UPDATE [datamart].[marks] SET [marks] = 95 WHERE [roll_number] = '111'

-- Validate test
GO
SELECT * FROM [datamart].[marks]
SELECT * FROM [audit].[marks]

-- Reset tables
GO
TRUNCATE TABLE [datamart].[marks]
TRUNCATE TABLE [audit].[marks]

-- Create test data teams
INSERT INTO [datamart].[teams] (team_name) VALUES ('Adam')
INSERT INTO [datamart].[teams] (team_name) VALUES ('Jane')
INSERT INTO [datamart].[teams] (team_name) VALUES ('Sally')
INSERT INTO [datamart].[teams] (team_name) VALUES ('Steve')
INSERT INTO [datamart].[teams] (team_name) VALUES ('Unknown')
