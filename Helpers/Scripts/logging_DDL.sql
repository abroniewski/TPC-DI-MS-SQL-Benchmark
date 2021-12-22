CREATE DATABASE [TPC_DI_Logging];
GO

USE [TPC_DI_Logging]
GO

CREATE TABLE [dbo].[Logging](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[LogType] [nvarchar](450) NULL,
	[Time] [datetime] NULL,
	[OrderFlag] [nvarchar](450) NULL,
	[ScaleFactor] [nvarchar](450) NULL,
	[RunID] [int] NULL
) ON [PRIMARY]
GO

CREATE VIEW [dbo].[TPCDSLoggingReport] AS
	SELECT S.RunID 'RunIdentifier'
		, S.LogType 'BenchmarkStep'
		, S.ScaleFactor 'ScaleFactor'
		, S.[Time] 'StartTime'
		, E.[Time] 'EndTime'
		, DATEDIFF( MILLISECOND, S.[Time], E.[Time] )/1000 'Duration'
	FROM [dbo].[Logging] S
		INNER JOIN [dbo].[Logging] E
			ON S.LogType = E.LogType AND S.ScaleFactor = E.ScaleFactor AND S.RunID = E.RunID AND S.OrderFlag = 'Start' AND E.OrderFlag = 'End'
GO