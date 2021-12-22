-- DimDate
INSERT INTO dbo.DimDate
    (SK_DateID,
    DateValue,
    DateDesc,
    CalendarYearID,
    CalendarYearDesc,
    CalendarQtrID,
    CalendarQtrDesc,
    CalendarMonthID,
    CalendarMonthDesc,
    CalendarWeekID,
    CalendarWeekDesc,
    DayOfWeeknumeric,
    DayOfWeekDesc,
    FiscalYearID,
    FiscalYearDesc,
    FiscalQtrID,
    FiscalQtrDesc,
    HolidayFlag)
SELECT
    SK_DateID,
    DateValue,
    DateDesc,
    CalendarYearID,
    CalendarYearDesc,
    CalendarQtrID,
    CalendarQtrDesc,
    CalendarMonthID,
    CalendarMonthDesc,
    CalendarWeekID,
    CalendarWeekDesc,
    DayOfWeekNum,
    DayOfWeekDesc,
    FiscalYearID,
    FiscalYearDesc,
    FiscalQtrID,
    FiscalQtrDesc,
    HolidayFlag
FROM Source.Date;
GO

-- DimTime
INSERT INTO dbo.DimTime ( SK_TimeID, TimeValue, HourID, HourDesc, MinuteID, MinuteDesc, SecondID, SecondDesc, MarketHoursFlag, OfficeHoursFlag )
SELECT  SK_TimeID, TimeValue, HourID, HourDesc, MinuteID, MinuteDesc, SecondID, SecondDesc, MarketHoursFlag, OfficeHoursFlag
FROM    Source.Time
GO

-- StatusType
INSERT INTO dbo.StatusType ( ST_ID, ST_NAME )
SELECT  ST_ID, ST_NAME
FROM    Source.StatusType

GO

-- TaxRate
INSERT INTO dbo.TaxRate ( TX_ID, TX_NAME, TX_RATE )
SELECT  TX_ID, TX_NAME, TX_RATE
FROM    Source.TaxRate

GO

-- TradeType
INSERT INTO dbo.TradeType ( TT_ID, TT_NAME, TT_IS_SELL, TT_IS_MRKT )
SELECT  TT_ID, TT_NAME, TT_IS_SELL, TT_IS_MRKT
FROM    Source.TradeType
GO

-- DimBroker
INSERT INTO dbo.DimBroker (IsCurrent, EffectiveDate, EndDate, BatchID, BrokerID, ManagerID, FirstName, LastName, MiddleInitial, Branch, Office, Phone)
SELECT 
	1 AS IsCurrent,
	(SELECT MIN(DateValue) FROM DimDate) as EffectiveDate,
	'9999-12-31' AS EndDate,
	1 as BatchID, 
	EmployeeID as BrokerID, 
	ManagerID as ManagerID, 
	EmployeeFirstName as FirstName, 
	EmployeeLastName as LastName, 
	EmployeeMI as MiddleInitial, 
	EmployeeBranch as Branch, 
	EmployeeOffice as Office, 
	EmployeePhone as Phone
FROM Source.HR
WHERE EmployeeJobCode = 314

GO

-- TODO: DImessages
-- DimCompany
INSERT INTO dbo.DimCompany (IsCurrent, EffectiveDate, EndDate, BatchID, CompanyID, Name, SPrating, CEO, Description, FoundingDate, AddressLine1, AddressLine2, PostalCode, City, StateProv, Country, Status, Industry, IsLowGrade)
SELECT
    -- NOTE: Standard Lead + Coalesce for most recent date
	CASE WHEN LEAD( (SELECT TOP 1 BatchDate FROM Source.BatchDate) ) OVER ( PARTITION BY CIK ORDER BY PTS ASC ) IS NULL THEN 1 ELSE 0 END AS IsCurrent,
	(SELECT TOP 1 BatchDate FROM Source.BatchDate) as EffectiveDate,
	COALESCE( LEAD( (SELECT TOP 1 BatchDate FROM Source.BatchDate) ) OVER ( PARTITION BY CIK ORDER BY PTS ASC ), '9999-12-31' ) AS EndDate,
	1 as BatchID, 
	CIK as CompanyID,
	CompanyName as Name, 
	SPrating as SPRating, 
	CEOname as CEO, 
	Description, 
	FoundingDate, 
	AddrLine1 as AddressLine1, 
	AddrLine2 as AddressLine2, 
	PostalCode, 
	City, 
	StateProvince as State_Prov, 
	Country,
	S.ST_NAME as Status,
	I.IN_NAME as Industry,
	(CASE WHEN SPrating LIKE 'A%' OR SPrating LIKE 'BBB%' THEN 0 ELSE 1 END) as IsLowGrade
FROM Source.FinwireCMP CMP, Source.StatusType S, Source.Industry I
WHERE CMP.Status = S.ST_ID
AND CMP.IndustryID = I.IN_ID

GO

-- DimCustomer
	WITH Customers_Preproc AS (
		SELECT CXML.C_ID AS CustomerID
		     -- NOTE: TRIM was used on all string values to ensure there are no leading spaces.
			, TRIM( CXML.C_TAX_ID ) AS TaxID
			, TRIM( UPPER( CASE WHEN CXML.C_GNDR NOT IN ( 'm', 'f' ) OR CXML.C_GNDR IS  NULL THEN 'u' ELSE CXML.C_GNDR END ) ) AS Gender
			, CXML.C_TIER AS Tier
			, CXML.C_DOB AS DOB
			, TRIM( CCIN.C_PRIM_EMAIL ) AS Email1
			, TRIM( CCIN.C_ALT_EMAIL ) AS Email2
			, TRIM( NXML.C_F_NAME ) AS FirstName
			, TRIM( NXML.C_M_NAME ) AS MiddleInitial
			, TRIM( NXML.C_L_NAME ) AS LastName
			, TRIM( ADXML.C_ADLINE1 ) AS AddressLine1
			, TRIM( ADXML.C_ADLINE2 ) AS AddressLine2
			, TRIM( ADXML.C_ZIPCODE ) AS PostalCode
			, TRIM( ADXML.C_CITY ) AS City
			, TRIM( ADXML.C_STATE_PROV ) AS StateProv
			, TRIM( ADXML.C_CTRY ) AS Country
			, CASE 
				WHEN CP1XML.C_CTRY_CODE IS NOT NULL AND CP1XML.C_AREA_CODE IS NOT NULL AND CP1XML.C_LOCAL IS NOT NULL 
					THEN '+' + CP1XML.C_CTRY_CODE + ' (' + CP1XML.C_AREA_CODE + ') ' + CP1XML.C_LOCAL 
				WHEN CP1XML.C_CTRY_CODE IS NULL AND ( CP1XML.C_AREA_CODE IS NOT NULL AND CP1XML.C_LOCAL IS NOT NULL ) 
					THEN '(' + CP1XML.C_AREA_CODE + ') ' + CP1XML.C_LOCAL
				WHEN ( CP1XML.C_CTRY_CODE IS NULL AND CP1XML.C_AREA_CODE IS NULL ) AND CP1XML.C_LOCAL IS NOT NULL 
					THEN CP1XML.C_LOCAL 
			END AS Phone1_V1
		     -- NOTE: completing pre-processing of phone numbers to make it more manageable and human readable
			, CASE 
				WHEN CP2XML.C_CTRY_CODE IS NOT NULL AND CP2XML.C_AREA_CODE IS NOT NULL AND CP2XML.C_LOCAL IS NOT NULL 
					THEN '+' + CP2XML.C_CTRY_CODE + ' (' + CP2XML.C_AREA_CODE + ') ' + CP2XML.C_LOCAL 
				WHEN CP2XML.C_CTRY_CODE IS NULL AND ( CP2XML.C_AREA_CODE IS NOT NULL AND CP2XML.C_LOCAL IS NOT NULL ) 
					THEN '(' + CP2XML.C_AREA_CODE + ') ' + CP2XML.C_LOCAL
				WHEN ( CP2XML.C_CTRY_CODE IS NULL AND CP2XML.C_AREA_CODE IS NULL ) AND CP2XML.C_LOCAL IS NOT NULL 
					THEN CP2XML.C_LOCAL 
			END AS Phone2_V1
			, CASE 
				WHEN CP3XML.C_CTRY_CODE IS NOT NULL AND CP3XML.C_AREA_CODE IS NOT NULL AND CP3XML.C_LOCAL IS NOT NULL 
					THEN '+' + CP3XML.C_CTRY_CODE + ' (' + CP3XML.C_AREA_CODE + ') ' + CP3XML.C_LOCAL 
				WHEN CP3XML.C_CTRY_CODE IS NULL AND ( CP3XML.C_AREA_CODE IS NOT NULL AND CP3XML.C_LOCAL IS NOT NULL ) 
					THEN '(' + CP3XML.C_AREA_CODE + ') ' + CP3XML.C_LOCAL
				WHEN ( CP3XML.C_CTRY_CODE IS NULL AND CP3XML.C_AREA_CODE IS NULL ) AND CP3XML.C_LOCAL IS NOT NULL 
					THEN CP3XML.C_LOCAL 
			END AS Phone3_V1
			, TRIM( TR.TX_NAME ) AS NationalTaxRateDesc
			, TR.TX_RATE AS NationalTaxRate
			, TRIM( TR2.TX_NAME ) AS LocalTaxRateDesc
			, TR2.TX_RATE AS LocalTaxRate
			, CP1XML.C_EXT AS C_EXT1
			, CP2XML.C_EXT AS C_EXT2
			, CP3XML.C_EXT AS C_EXT3
			, TRIM( P.AgencyID ) AS AgencyID
			, P.CreditRating
			, P.NetWorth
			, CASE 
				WHEN P.NetWorth > 1000000 OR P.Income > 200000 THEN 'HighValue'
				WHEN P.NumberChildren > 3 OR P.NumberCreditCards > 5 THEN 'Expenses'
				WHEN P.Age > 45 THEN 'Boomer'
				WHEN P.Income < 50000 OR P.CreditRating < 600 OR P.NetWorth < 100000 THEN 'MoneyAlert'
				WHEN P.NumberCars > 3 OR P.NumberCreditCards > 7 THEN 'Spender'
				WHEN P.Age < 25 AND P.NetWorth > 1000000 THEN 'Inherited'
			END AS MarketingNameplate
			, AXML.ActionType
			, AXML.ActionTS
		-- NOTE: Created intermediate tables to make the process more manageable
		FROM [Source].[CustomerXML] CXML
			LEFT JOIN [Source].[ActionXML] AXML
				ON CXML.Action_Id = AXML.Action_Id
			LEFT JOIN [Source].[NameXML] NXML
				ON CXML.Customer_Id = NXML.Customer_Id
			LEFT JOIN [Source].[ContactInfoXML] CCIN
				ON CXML.Customer_Id = CCIN.Customer_Id
			LEFT JOIN [Source].[AddressXML] ADXML
				ON CXML.Customer_Id = ADXML.Customer_Id
			LEFT JOIN [Source].[TaxInfoXML] TXML
				ON CXML.Customer_Id = TXML.Customer_Id
			LEFT JOIN [Source].[TaxRate] TR
				ON TXML.C_NAT_TX_ID = TR.TX_ID
			LEFT JOIN [Source].[TaxRate] TR2
				ON TXML.C_LCL_TX_ID = TR2.TX_ID
			LEFT JOIN [Source].[C_PHONE_1_XML] CP1XML
				ON CCIN.ContactInfo_Id = CP1XML.ContactInfo_Id
			LEFT JOIN [Source].[C_PHONE_2_XML] CP2XML
				ON CCIN.ContactInfo_Id = CP2XML.ContactInfo_Id
			LEFT JOIN [Source].[C_PHONE_3_XML] CP3XML
				ON CCIN.ContactInfo_Id = CP3XML.ContactInfo_Id
			LEFT JOIN [Source].[Prospect] P
				ON
				    -- NOTE: Needed to do TRIM to deal with leading empty spaces
				    -- NOTE: Cast to UPPER case for matching
				    -- NOTE: COALESCE was used to join data if the value exists, if DNE, it still joins, but with
				    --  missing values. TPC-DI does not have it explicit. Address line 2 can be NULL as per the rules.
				    --  if the value is NULL on one side, it will be NULL on the other. Must be missing on both sides
				    --  for this to match.
					-- Join on FirstName if exists
					COALESCE( UPPER( TRIM( NXML.C_F_NAME ) ), ' ' ) = COALESCE( UPPER( TRIM( P.FirstName ) ), ' ' )
					-- Join on LastName if exists
					AND COALESCE( UPPER( TRIM( NXML.C_L_NAME ) ), ' ' ) = COALESCE( UPPER( TRIM( P.LastName ) ), ' ' )
					-- Join on AddressLine1 if exists
					AND COALESCE( UPPER( TRIM( ADXML.C_ADLINE1 ) ), ' ' ) = COALESCE( UPPER( TRIM( P.AddressLine1 ) ), ' ' )
					-- Join on AddressLine2 if exists
					AND COALESCE( UPPER( TRIM( ADXML.C_ADLINE2 ) ), ' ' ) = COALESCE( UPPER( TRIM( P.AddressLine2 ) ), ' ' )
					-- Join on PostalCode if exists
					AND COALESCE( UPPER( TRIM( ADXML.C_ZIPCODE ) ), ' ' ) = COALESCE( UPPER( TRIM( P.PostalCode ) ), ' ' )
	)

	, Customers AS (
	    -- NOTE: SELECT everything from previously defined tables + adding phones.
		SELECT *
			, CASE WHEN C_EXT1 IS NOT NULL THEN Phone1_V1 + C_EXT1 ELSE Phone1_V1 END Phone1
			, CASE WHEN C_EXT2 IS NOT NULL THEN Phone2_V1 + C_EXT2 ELSE Phone2_V1 END Phone2
			, CASE WHEN C_EXT3 IS NOT NULL THEN Phone3_V1 + C_EXT3 ELSE Phone3_V1 END Phone3
		FROM Customers_Preproc
	)
-- NOTE: Depending on what status of the customer, will use conditional logic to determine how to update the table.
	   -- These are the three cases. Take big table and subsect it into NEW, UPDATED, and INACTIVE
	, CustomersNew AS (
		SELECT *, 'ACTIVE' AS [Status] FROM Customers WHERE ActionType = 'NEW'
	)

	, CustomersUpd AS (
		SELECT * FROM Customers WHERE ActionType = 'UPDCUST'
	)

	, CustomersInactive AS (
		SELECT C_ID, ActionTS
		FROM [Source].[CustomerXML] CXML
			INNER JOIN [Source].[ActionXML] AXML
				ON CXML.Action_Id = AXML.Action_Id
		WHERE ActionType = 'INACT'
	)
-- NOTE: For new customers, simply insert all the info.
	, CustomersNewAndUpd AS (
		SELECT CustomerID
				, TaxID
				, 'ACTIVE' AS [Status]
				, LastName
				, FirstName
				, MiddleInitial
				, Gender
				, Tier
				, DOB
				, AddressLine1
				, AddressLine2
				, PostalCode
				, City
				, StateProv
				, Country
				, Phone1
				, Phone2
				, Phone3
				, Email1
				, Email2
				, NationalTaxRateDesc
				, NationalTaxRate
				, LocalTaxRateDesc
				, LocalTaxRate
				, AgencyID
				, CreditRating
				, NetWorth
				, MarketingNameplate
				, ActionTS
				, ActionType
				--, AS EffectiveDate
				--, AS EndDate
		FROM CustomersNew
		UNION
		-- NOTE: column for updated customer has NULL values anywhere there is no change. Any updated values (can be
		--  multiple updates can take place) need to be reflected in table.
		-- UPDCUST
		SELECT  NC.CustomerID
		     -- NOTE: If in the updated version of the cusomter, there is a TaxID, use the new TaxID. If the updated
		     --     version is NULL, use the existing TaxID. Order of COALESCE is what determines which one gets chosen.
		     --     if first parameter is NULL, the 2nd parameter is chosen. Preference is given to the first value, in this
		     --     case it is UC version.
				, COALESCE( UC.TaxID, NC.TaxID ) AS TaxID
				, NC.[Status] AS [Status]
				, COALESCE( UC.LastName, NC.LastName ) AS LastName
				, COALESCE( UC.FirstName, NC.FirstName ) AS FirstName
				, COALESCE( UC.MiddleInitial, NC.MiddleInitial ) AS MiddleInitial
				, COALESCE( UC.Gender, NC.Gender ) AS Gender
				, COALESCE( UC.Tier, NC.Tier ) AS Tier
				, COALESCE( UC.DOB, NC.DOB ) AS DOB
				, COALESCE( UC.AddressLine1, NC.AddressLine1 ) AS AddressLine1
				, COALESCE( UC.AddressLine2, NC.AddressLine2 ) AS AddressLine2
				, COALESCE( UC.PostalCode, NC.PostalCode ) AS PostalCode
				, COALESCE( UC.City, NC.City ) AS City
				, COALESCE( UC.StateProv, NC.StateProv ) AS StateProv
				, COALESCE( UC.Country, NC.Country ) AS Country
				, COALESCE( UC.Phone1, NC.Phone1 ) AS Phone1
				, COALESCE( UC.Phone2, NC.Phone2 ) AS Phone2
				, COALESCE( UC.Phone3, NC.Phone3 ) AS Phone3
				, COALESCE( UC.Email1, NC.Email1 ) AS Email1
				, COALESCE( UC.Email2, NC.Email2 ) AS Email2
				, COALESCE( UC.NationalTaxRateDesc, NC.NationalTaxRateDesc ) AS NationalTaxRateDesc
				, COALESCE( UC.NationalTaxRate, NC.NationalTaxRate ) AS NationalTaxRate
				, COALESCE( UC.LocalTaxRateDesc, NC.LocalTaxRateDesc ) AS LocalTaxRateDesc
				, COALESCE( UC.LocalTaxRate, NC.LocalTaxRate ) AS LocalTaxRate
				, COALESCE( UC.AgencyID, NC.AgencyID ) AS AgencyID
				, COALESCE( UC.CreditRating, NC.CreditRating ) AS CreditRating
				, COALESCE( UC.NetWorth, NC.NetWorth ) AS NetWorth
				, COALESCE( UC.MarketingNameplate, NC.MarketingNameplate ) AS MarketingNameplate
				, UC.ActionTS
				, UC.ActionType
		FROM CustomersNew NC
		    -- NOTE: New row is created for each update. We now have a row for the NC, and each UC that took place.
		    --  there is a date that exists for each update that took place.
			INNER JOIN CustomersUpd UC
				ON NC.CustomerID = UC.CustomerID
	)

	, CustomersFinal AS (
		-- NEW and UPDCUST
		SELECT * 
		FROM CustomersNewAndUpd
		UNION
		-- NOTE: No need to update date, just grab the latest version and change the Status value from Active to
		--  inactive.
		-- INACT
		SELECT CNU.CustomerID
					, CNU.TaxID
					, 'INACTIVE' AS [Status]
					, CNU.LastName
					, CNU.FirstName
					, CNU.MiddleInitial
					, CNU.Gender
					, CNU.Tier
					, CNU.DOB
					, CNU.AddressLine1
					, CNU.AddressLine2
					, CNU.PostalCode
					, CNU.City
					, CNU.StateProv
					, CNU.Country
					, CNU.Phone1
					, CNU.Phone2
					, CNU.Phone3
					, CNU.Email1
					, CNU.Email2
					, CNU.NationalTaxRateDesc
					, CNU.NationalTaxRate
					, CNU.LocalTaxRateDesc
					, CNU.LocalTaxRate
					, CNU.AgencyID
					, CNU.CreditRating
					, CNU.NetWorth
					, CNU.MarketingNameplate
					, CI.ActionTS
					, 'INACT' AS ActionType
		FROM CustomersNewAndUpd CNU
			INNER JOIN CustomersInactive CI
				ON CNU.CustomerID = CI.C_ID
			INNER JOIN (
			    -- NOTE: ActionTS is the timestamp on which the register was updated. Grouped By CustID, so it pulls
			    --  the most up to date cutomer row to be able to set it to INACT.
				SELECT CustomerID, MAX( ActionTS ) ActionTSLatestCustomer
				FROM CustomersNewAndUpd
				GROUP BY CustomerID
			) LC 
			ON CNU.CustomerID = LC.CustomerID AND CNU.ActionTS = LC.ActionTSLatestCustomer
	)

	INSERT INTO dbo.DimCustomer
	SELECT CustomerID
			, TaxID
			, [Status]
			, LastName
			, FirstName
			, MiddleInitial
			, Gender
			, Tier
			, DOB
			, AddressLine1
			, AddressLine2
			, PostalCode
			, City
			, StateProv
			, Country
			, Phone1
			, Phone2
			, Phone3
			, Email1
			, Email2
			, NationalTaxRateDesc
			, NationalTaxRate
			, LocalTaxRateDesc
			, LocalTaxRate
			, AgencyID
			, CreditRating
			, NetWorth
			, MarketingNameplate
	     -- NOTE: Check to see if this row is the most current in the table. Create a IsCurrent row. Whenever the
	     --     row stops being the latest value, make the IsCurrent value 0. For the most up to date value you use
	     --     "1" as the indicator here. Lead looks at the row above me (which is the previous row in time based on
	     --     the sort we do. If the value is NULL, we know that this is the most current value.)
			, CASE WHEN LEAD( ActionTS ) OVER ( PARTITION BY CustomerID ORDER BY ActionTS ASC ) IS NULL THEN 1 ELSE 0 END AS IsCurrent
			, 1 AS BatchID
			, ActionTS AS EffectiveDate
			, COALESCE( LEAD( ActionTS ) OVER ( PARTITION BY CustomerID ORDER BY ActionTS ASC ), '9999-12-31 00:00:00' ) AS EndDate
	FROM CustomersFinal
	ORDER BY CustomerID, ActionTS ASC
GO

-- DimAccount
WITH Accounts AS (
	SELECT Acc.CA_ID AS AccountID
		, Br.SK_BrokerID AS SK_BrokerID
		, DimC.SK_CustomerID AS SK_CustomerID
		, Acc.Customer_Id AS Customer_Id
		, Acc.CA_NAME AS AccountDesc
		, Acc.CA_TAX_ST AS TaxStatus
		, ActionType
		, ActionTS
	FROM Source.CustomerXML C
		INNER JOIN Source.ActionXML Act
			ON C.Action_Id = Act.Action_Id
		INNER JOIN Source.AccountXML Acc
			ON C.Customer_Id = Acc.Customer_Id
		INNER JOIN dbo.DimBroker Br
			ON Acc.CA_B_ID = Br.BrokerID
		INNER JOIN dbo.DimCustomer DimC
			ON C.C_ID = DimC.CustomerID
	WHERE Act.ActionTS >= DimC.EffectiveDate
	  AND Act.ActionTS <= DimC.EndDate
)

, AccountsNewAndAddAcct AS (
	SELECT *, 'ACTIVE' AS [Status]
	FROM Accounts
	WHERE ActionType IN ('NEW', 'ADDACCT')
)

, AccountsUpd AS (
	SELECT * FROM Accounts WHERE ActionType = 'UPDACCT'
)

, AccountsCloseAcct AS (
	SELECT Acc.CA_ID AS AccountID
		, Act.ActionTS AS ActionTS
	FROM Source.AccountXML Acc
		INNER JOIN Source.CustomerXML C
			ON C.Customer_Id = Acc.Customer_Id
		INNER JOIN Source.ActionXML Act
			ON C.Action_Id = Act.Action_Id
	WHERE ActionType = 'CLOSEACCT'
)

, AccountsNewAndAddAcctAndUpd AS (
	SELECT AccountID
		, SK_BrokerID
		, SK_CustomerID
		, 'ACTIVE' AS [Status]
		, AccountDesc
		, TaxStatus
		, ActionTS
		, ActionType
	FROM AccountsNewAndAddAcct
	UNION
	SELECT UpdAcct.AccountID
		, COALESCE( UpdAcct.SK_BrokerID, NewAcct.SK_BrokerID ) AS SK_BrokerID
		, COALESCE( UpdAcct.SK_CustomerID, NewAcct.SK_CustomerID ) AS SK_CustomerID
		, NewAcct.[Status] AS [Status]
		, COALESCE ( UpdAcct.AccountDesc, NewAcct.AccountDesc ) AS AccountDesc
		, COALESCE ( UpdAcct.TaxStatus, NewAcct.TaxStatus) AS TaxStatus
		, UpdAcct.ActionTS
		, UpdAcct.ActionType
	FROM AccountsNewAndAddAcct NewAcct 
		INNER JOIN AccountsUpd UpdAcct 
			ON NewAcct.AccountID = UpdAcct.AccountID
)

/*, AccountsUpdCust AS (
/* When ./@ActionType is UPDCUST
 For each account held by the customer being updated, perform an update to:
 Set SK_CustomerID to the associated customers DimCustomer current record after it has
been updated. */
		select *
	FROM Source.CustomerXML C
		INNER JOIN Source.ActionXML Act
			ON C.Action_Id = Act.Action_Id WHERE ActionType = 'UPDCUST'
)*/

, AccountsFinal AS (
	-- NEW, ADDACCT and UPDACCT
	SELECT *
	FROM AccountsNewAndAddAcctAndUpd
	UNION
	-- CLOSEACCT
	SELECT AcctNewUpd.AccountID
		, SK_BrokerID
		, SK_CustomerID
		, 'INACTIVE' AS [Status]
		, AccountDesc
		, TaxStatus
		, AcctNewUpd.ActionTS
		, 'CLOSEACCT' AS ActionType
	FROM AccountsNewAndAddAcctAndUpd AcctNewUpd
		INNER JOIN AccountsCloseAcct AcctClose 
			ON AcctNewUpd.AccountID = AcctClose.AccountID 
		INNER JOIN (
			SELECT AccountID, MAX( ActionTS ) AS ActionTSLatestAccount
			FROM AccountsNewAndAddAcctAndUpd
			GROUP BY AccountID
		) LastAcct
			ON AcctNewUpd.AccountID = LastAcct.AccountID
			AND AcctNewUpd.ActionTS = LastAcct.ActionTSLatestAccount
)

INSERT INTO dbo.DimAccount
SELECT AccountID
      , SK_BrokerID
      , SK_CustomerID
      , [Status]
      , AccountDesc
      , TaxStatus
      , CASE WHEN LEAD( ActionTS ) OVER ( PARTITION BY AccountID ORDER BY ActionTS ASC ) IS NULL THEN 1 ELSE 0 END AS IsCurrent
      , 1 AS BatchID
      , ActionTS AS EffectiveDate
      , COALESCE( LEAD( ActionTS ) OVER ( PARTITION BY AccountID ORDER BY ActionTS ASC ), '9999-12-31 00:00:00' ) AS EndDate
	--   , ActionType
FROM AccountsFinal
ORDER BY AccountID, ActionTS ASC
GO

-- DimSecurity (#FIXME FROM HERE ON) 
WITH SecurityFinal AS (
	SELECT F.Symbol AS Symbol
		, F.IssueType AS Issue
		, ST.ST_NAME AS [Status]
		, F.[Name] AS [Name]
		, F.ExID AS ExchangeID
		, DimCo.SK_CompanyID AS SK_CompanyID
		, F.ShOut AS SharesOutstanding
		, F.FirstTradeDate AS FirstTrade
		, F.FirstTradeExchg AS FirstTradeOnExchange
		, F.Dividend AS Dividend
		-- , IsCurrent
		--, 1 as BatchID 
		, CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(REPLACE(F.PTS,'-',' '),5,0,'-'),8,0,'-'),14,0,':'),17,0,':'),120) AS EffectiveDate
		-- , EndDate
	FROM Source.FinwireSEC F
	INNER JOIN DimCompany DimCo
		ON (CASE 
			WHEN ISNUMERIC(F.CoNameOrCIK) = 1 THEN CAST(DimCo.CompanyID AS VARCHAR) --TODO: improve query because it is joining varchars
			ELSE DimCo.[Name]
		END) = F.CoNameOrCIK
	INNER JOIN StatusType ST
		ON F.[Status] = ST.ST_ID
	WHERE F.RecType = 'SEC'
	-- AND F.PTS >= EffectiveDate --YYYYMMDD-HHMMSS
	-- AND F.PTS < EndDate
		AND CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(REPLACE(F.PTS,'-',' '),5,0,'-'),8,0,'-'),14,0,':'),17,0,':'),120) >= EffectiveDate
		AND CONVERT(DATETIME,STUFF(STUFF(STUFF(STUFF(REPLACE(F.PTS,'-',' '),5,0,'-'),8,0,'-'),14,0,':'),17,0,':'),120) < EndDate
)

INSERT INTO dbo.DimSecurity(Symbol, Issue, [Status], [Name], ExchangeID, SK_CompanyID, SharesOutstanding, FirstTrade, FirstTradeOnExchange, Dividend, IsCurrent, BatchID, EffectiveDate, EndDate)
SELECT Symbol
      , Issue
      , [Status]
      , [Name]
      , ExchangeID
      , SK_CompanyID
      , SharesOutstanding
      , FirstTrade
      , FirstTradeOnExchange
      , Dividend
      , CASE WHEN LEAD( EffectiveDate ) OVER ( PARTITION BY Symbol ORDER BY EffectiveDate ASC ) IS NULL THEN 1 ELSE 0 END AS IsCurrent
      , 1 AS BatchID
      , EffectiveDate
      , COALESCE( LEAD( EffectiveDate ) OVER ( PARTITION BY Symbol ORDER BY EffectiveDate ASC ), '9999-12-31 00:00:00' ) AS EndDate
FROM SecurityFinal
ORDER BY Symbol, EffectiveDate
GO


-- DimTrade
WITH DimTradeStaging AS (
	SELECT T.T_ID AS TradeID
		, 1 AS SK_BrokerID -- FIX SK
		, CASE 
			WHEN TH.TH_ST_ID = 'SBMT' AND T.T_TT_ID IN ( 'TMB', 'TMS' ) OR TH.TH_ST_ID = 'PNDG' THEN TH.TH_DTS
			WHEN TH.TH_ST_ID IN ( 'CMPT', 'CNCL' ) THEN NULL
		END AS SK_CreateDateID
		, CASE 
			WHEN TH.TH_ST_ID = 'SBMT' AND T.T_TT_ID IN ( 'TMB', 'TMS' ) OR TH.TH_ST_ID = 'PNDG' THEN TH.TH_DTS
			WHEN TH.TH_ST_ID IN ( 'CMPT', 'CNCL' ) THEN NULL
		END AS SK_CreateTimeID
		, CASE 
			WHEN TH.TH_ST_ID = 'SBMT' AND T.T_TT_ID IN ( 'TMB', 'TMS' ) OR TH.TH_ST_ID = 'PNDG' THEN NULL
			WHEN TH.TH_ST_ID IN ( 'CMPT', 'CNCL' ) THEN TH.TH_DTS
		END AS SK_CloseDateID
		, CASE 
			WHEN TH.TH_ST_ID = 'SBMT' AND T.T_TT_ID IN ( 'TMB', 'TMS' ) OR TH.TH_ST_ID = 'PNDG' THEN NULL
			WHEN TH.TH_ST_ID IN ( 'CMPT', 'CNCL' ) THEN TH.TH_DTS
		END AS SK_CloseTimeID
		, ST.ST_NAME AS [Status]
		, TT.TT_NAME AS DT_Type
		, T.T_IS_CASH AS CashFlag
		, 1 AS SK_SecurityID -- FIX SK
		, 1 AS SK_CompanyID  -- FIX SK
		, T.T_QTY AS Quantity
		, T.T_BID_PRICE AS BidPrice
		, 1 AS SK_CustomerID  -- FIX SK
		, 1 AS SK_AccountID -- FIX SK
		, T.T_EXEC_NAME AS ExecutedBy
		, T.T_TRADE_PRICE AS TradePrice
		, T.T_CHRG AS Fee
		, T.T_COMM AS Commission
		, T.T_TAX AS Tax
		, 1 AS BatchID
	FROM [Source].[Trade] T
		INNER JOIN [Source].[TradeHistory] TH
			ON T.T_ID = TH.TH_T_ID
		INNER JOIN [Source].[StatusType] ST
			ON T.T_ST_ID = ST.ST_ID
		INNER JOIN [Source].[TradeType] TT
			ON T.T_TT_ID = TT.TT_ID
		--INNER JOIN dbo.DimSecurity DS
		--	ON T.T_S_SYMB = DS.Symbol
			--AND ON ( TH.TH_DTS BETWEEN DS.EffectiveDate AND DS.EndDate )
)

INSERT INTO dbo.DimTrade
SELECT TradeID
	, SK_BrokerID
	, ( SELECT SK_DateID FROM dbo.DimDate WHERE DateValue = CAST( SK_CreateDateID AS DATE ) ) AS SK_CreateDateID
	, ( SELECT SK_TimeID FROM dbo.DimTime WHERE TimeValue = CAST( SK_CreateTimeID AS TIME ) ) AS SK_CreateTimeID
	, ( SELECT SK_DateID FROM dbo.DimDate WHERE DateValue = CAST( SK_CloseDateID AS DATE ) ) AS SK_CloseDateID
	, ( SELECT SK_TimeID FROM dbo.DimTime WHERE TimeValue = CAST( SK_CloseTimeID  AS TIME ) ) AS SK_CloseTimeID
	,[Status]
	, DT_Type
	, CashFlag
	, SK_SecurityID 
	, SK_CompanyID  
	, Quantity
	, BidPrice
	, SK_CustomerID  
	, SK_AccountID 
	, ExecutedBy
	, TradePrice
	, Fee
	, Commission
	, Tax
	, BatchID 
FROM DimTradeStaging

-- FactCashBalances
INSERT INTO FactCashBalances(SK_CustomerID, SK_AccountID, SK_DateID, BatchID, Cash)
SELECT
	DA.SK_CustomerID AS SK_CustomerID,
	DA.SK_AccountID AS SK_AccountID,
	DD.SK_DateID AS SK_DateID,
	1 AS BatchID,
	SUM(CT_AMT) AS Cash -- TODO: Add to previous account balance (after having DimAccount)
FROM Source.CashTransaction CT, DimAccount DA, DimDate DD
WHERE CT.CT_CA_ID = DA.AccountID
	AND CONVERT(DATE, CT_DTS) BETWEEN DA.EffectiveDate AND DA.EndDate
	AND CONVERT(DATE, CT_DTS) = DD.DateValue
GROUP BY 
	DA.SK_CustomerID,
	DA.SK_AccountID,
	DD.SK_DateID,
	CONVERT(DATE, CT_DTS)

-- FactHoldings
INSERT INTO FactHoldings(SK_CustomerID, SK_AccountID, SK_SecurityID, SK_CompanyID, CurrentPrice, SK_DateID, SK_TimeID, TradeID, CurrentTradeID, CurrentHolding, BatchID)
SELECT 
	DT.SK_CustomerID, 
	DT.SK_AccountID, 
	DT.SK_SecurityID, 
	DT.SK_CompanyID,
       -- NOTE: Used TradePrice as this seemed like the field that made sense, but not explicit in TPC-DI spec.
	DT.TradePrice AS CurrentPrice, -- QUESTION: What field should we use for CurrentPrice?
	SK_CloseDateID AS SK_DateID,
	SK_CloseTimeID AS SK_TimeID,
	HH.HH_H_T_ID AS TradeID,
	HH.HH_T_ID AS CurrentTradeID,
	HH.HH_AFTER_QTY AS CurrentHolding,
	1 AS BatchID
FROM Source.HoldingHistory HH, DimTrade DT
WHERE HH.HH_T_ID = DT.TradeID
GO



-- TODO: DImessages
---- FactMarketHistory
--WITH DailyMarkets AS (
--	SELECT DM1.*, MIN(DM2.DM_DATE) AS FiftyTwoWeekHighDate, MIN(DM3.DM_DATE) AS FiftyTwoWeekLowDate
--	FROM
--	(
--		SELECT 
--			DM_DATE, 
--			DM_S_SYMB, 
--			DM_CLOSE, 
--			DM_HIGH, 
--			DM_LOW, 
--			DM_VOL, 
--			MAX(DM_HIGH) OVER(PARTITION BY DM_S_SYMB ORDER BY DM_DATE ROWS BETWEEN 364 PRECEDING AND CURRENT ROW) AS FiftyTwoWeekHigh, 
--			MIN(DM_LOW) OVER(PARTITION BY DM_S_SYMB ORDER BY DM_DATE ROWS BETWEEN 364 PRECEDING AND CURRENT ROW) AS FiftyTwoWeekLow
--		FROM Source.DailyMarket
--	    -- NOTE: Self join 3 times. DM1 is main. DM2 is used to calculate 52-week high, DM3 calculates 52 week low
--	) DM1
--	INNER JOIN Source.DailyMarket DM2
--		ON DM2.DM_HIGH = DM1.FiftyTwoWeekHigh
--		AND DM2.DM_DATE BETWEEN CONVERT(DATE, DATEADD(DAY, -364, DM1.DM_DATE)) AND DM1.DM_DATE
--	INNER JOIN Source.DailyMarket DM3
--		ON DM3.DM_LOW = DM1.FiftyTwoWeekLow
--		AND DM3.DM_DATE BETWEEN CONVERT(DATE, DATEADD(DAY, -364, DM1.DM_DATE)) AND DM1.DM_DATE
--	GROUP BY DM1.DM_DATE, DM1.DM_S_SYMB, DM1.DM_CLOSE, DM1.DM_HIGH, DM1.DM_LOW, DM1.DM_VOL, DM1.FiftyTwoWeekHigh, DM1.FiftyTwoWeekLow
--),
--     -- NOTE: Earnings per share by quarter for each company
--FIN AS (
--	SELECT
--		CoNameOrCIK,
--		SUM(CAST(EPS AS FLOAT)) OVER(PARTITION BY Quarter ORDER BY Year, Quarter ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS EPSSum
--	FROM Source.FinwireFIN
--),
--     -- NOTE: Checks if CoNameOrCIK is numeric or string. numerics are UNION with strings
--CompanyEarnings AS (
--	SELECT DISTINCT SK_CompanyID, EPSSum
--	FROM DimCompany DC, FIN
--	WHERE ISNUMERIC(FIN.CoNameOrCIK) = 1
--	AND DC.CompanyID = CAST(FIN.CoNameOrCIK AS INT)
--	UNION
--	SELECT DISTINCT SK_CompanyID, EPSSum
--	FROM DimCompany DC,  FIN
--	WHERE ISNUMERIC(FIN.CoNameOrCIK) = 0
--	AND DC.Name = FIN.CoNameOrCIK
--)
----INSERT INTO FactMarketHistory(ClosePrice, DayHigh, DayLow, Volume, SK_SecurityID, SK_CompanyID, SK_DateID, FiftyTwoWeekHigh, SK_FiftyTwoWeekHighDate, FiftyTwoWeekLow, SK_FiftyTwoWeekLowDate, PERatio, Yield, BatchID)
--SELECT
--	DM.DM_CLOSE AS ClosePrice, 
--	DM.DM_HIGH AS DayHigh, 
--	DM.DM_LOW AS DayLow,
--	DM.DM_VOL AS Volume,
--	--DS.SK_SecurityID,
--	--DS.SK_CompanyID,
--	DD1.SK_DateID AS SK_DateID,
--	DM.FiftyTwoWeekHigh,
--	DD2.SK_DateID AS SK_FiftyTwoWeekHighDate,
--	DM.FiftyTwoWeekLow,
--	DD3.SK_DateID AS SK_FiftyTwoWeekLowDate,
--	DM.DM_CLOSE / CE.EPSSum AS PERatio,
--	--dividend / DM_CLOSE * 100 AS Yield, 
--	1 AS BatchID
--FROM DailyMarkets DM, /*DimSecurity DS,*/ CompanyEarnings CE, DimDate DD1, DimDate DD2, DimDate DD3
--WHERE /*DM.DM_S_SYMB = DS.Symbol
--AND DM.DM_DATE BETWEEN DS.EffectiveDate AND DS.EndDate
--AND DS.SK_CompanyID = CE.SK_CompanyID
--AND */DM.DM_DATE = DD1.DateValue
--AND DM.FiftyTwoWeekHighDate = DD2.DateValue
--AND DM.FiftyTwoWeekLowDate = DD3.DateValue

--GO


-- FactWatches

--INSERT INTO FactWatches(SK_CustomerID, SK_SecurityID, SK_DateID_DatePlaced, SK_DateID_DateRemoved, BatchID)
--SELECT 
--	DC.SK_CustomerID,
--	DS.SK_SecurityID,
--	DD.SK_DateID AS SK_DateID_DatePlaced,
--	NULL AS SK_DateID_DateRemoved,
--	1 AS BatchID
--FROM Source.WatchHistory WH, ( SELECT SK_CustomerID, CustomerID, EffectiveDate, EndDate FROM DimCustomer WHERE IsCurrent = 1 ) AS DC, DimSecurity DS, DimDate DD
---- NOTE: Start by inserting where W_Action is Active. Then, do an update (below) for anywhere the action is cancelled,
----  we update the DateRemoved column with the cancelled date
--WHERE WH.W_ACTION = 'ACTV'
--AND WH.W_C_ID = DC.CustomerID
--AND WH.W_DTS BETWEEN DC.EffectiveDate AND DC.EndDate
--AND WH.W_S_SYMB = DS.Symbol
--AND WH.W_DTS BETWEEN DS.EffectiveDate AND DS.EndDate
--AND WH.W_DTS = DD.DateValue

--UPDATE FactWatches
--	SET SK_DateID_DateRemoved = DD.SK_DateID
--FROM Source.WatchHistory WH, DimCustomer DC, DimSecurity DS, DimDate DD
--WHERE WH.W_ACTION = 'CNCL'
--AND WH.W_C_ID = DC.CustomerID
--AND WH.W_DTS BETWEEN DC.EffectiveDate AND DC.EndDate
--AND WH.W_S_SYMB = DS.Symbol
--AND WH.W_DTS BETWEEN DS.EffectiveDate AND DS.EndDate
--AND WH.W_DTS = DD.DateValue

--GO


-- Industry
INSERT INTO dbo.Industry ( IN_ID, IN_NAME, IN_SC_ID )
SELECT  IN_ID, IN_NAME, IN_SC_ID
FROM    Source.Industry
GO

-- Financial
	WITH DimFinancialStaging AS (
	    -- NOTE: research paper point this one out. date (PTS) format for this table (FINWIRE) had to be parsed and
	    --  and converted into format that we could use. Had to complete manual parsing for this.
		SELECT CAST( CONCAT( SUBSTRING( PTS, 0, 5 ), '-', SUBSTRING( PTS, 5, 2 ) , '-', SUBSTRING( PTS, 7, 2 ), ' ', SUBSTRING( PTS, 10, 2 ), ':', SUBSTRING( PTS, 12, 2 ), ':', SUBSTRING( PTS, 14, 2 ) ) AS DATETIME ) AS PTS
			, CASE WHEN ISNUMERIC( CoNameOrCIK ) = 1 THEN CAST( CoNameOrCIK AS INT ) ELSE NULL END CIK
			, CASE WHEN ISNUMERIC( CoNameOrCIK ) = 0 THEN CoNameOrCIK ELSE NULL END CoName
			, Year AS FI_YEAR
			, Quarter AS FI_QTR
			, QtrStartDate AS FI_QTR_START_DATE
			, Revenue AS FI_REVENUE
			, Earnings AS FI_NET_EARN
			, EPS AS FI_BASIC_EPS
			, DilutedEPS AS FI_DILUT_EPS
			, Margin AS FI_MARGIN
			, Inventory AS FI_INVENTORY
			, Assets AS FI_ASSETS
			, Liabilities AS FI_LIABILITY
			, ShOut AS FI_OUT_BASIC
			, DilutedShOut AS FI_OUT_DILUT
		FROM [Source].[FinwireFIN] F
	)

	INSERT INTO dbo.Financial
	SELECT ( 
			SELECT DC.SK_CompanyID 
			FROM dbo.DimCompany DC 
			WHERE ( DS.CIK = DC.CompanyID OR DS.CoName = DC.Name )
			--AND DC.EffectiveDate <= DS.PTS
			--AND DS.PTS < DC.EndDate
			AND DC.IsCurrent = 1
		) AS SK_CompanyID
		, FI_YEAR
		, FI_QTR
		, FI_QTR_START_DATE
		, FI_REVENUE
		, FI_NET_EARN
		, FI_BASIC_EPS
		, FI_DILUT_EPS
		, FI_MARGIN
		, FI_INVENTORY
		, FI_ASSETS
		, FI_LIABILITY
		, FI_OUT_BASIC
		, FI_OUT_DILUT
	FROM DimFinancialStaging DS
GO

-- Prospect
	INSERT INTO dbo.Prospect
	SELECT AgencyID
		, ( SELECT SK_DateID 
			FROM dbo.DimDate
			WHERE DateValue = (SELECT BatchDate FROM [Source].[BatchDate]) ) AS SK_RecordDateID
		, ( SELECT SK_DateID 
			FROM dbo.DimDate
			WHERE DateValue = (SELECT BatchDate FROM [Source].[BatchDate]) ) AS SK_UpdateDateID
		, 1 AS BatchID
		, (  
			SELECT COUNT(*)
			FROM dbo.DimCustomer DC 
			WHERE UPPER( DC.FirstName ) = UPPER( P.FirstName )	
				AND UPPER( DC.LastName ) = UPPER( P.LastName )
				AND UPPER( DC.AddressLine1 ) = UPPER( P.AddressLine1 )
				AND UPPER( DC.AddressLine2 ) = UPPER( P.AddressLine2 )
				AND UPPER( DC.PostalCode ) = UPPER( P.PostalCode )
				AND DC.Status = 'ACTIVE'
		) AS IsCustomer
		, LastName
		, FirstName
		, MiddleInitial
		, Gender
		, AddressLine1
		, AddressLine2
		, PostalCode
		, City
		, State
		, Country
		, Phone
		, Income
		, numberCars
		, numberChildren
		, MaritalStatus
		, Age
		, CreditRating
		, OwnOrRentFlag
		, Employer
		, numberCreditCards
		, NetWorth
		, CASE 
			WHEN NetWorth > 1000000 OR Income > 200000 THEN 'HighValue'
			WHEN NumberChildren > 3 OR NumberCreditCards > 5 THEN 'Expenses'
			WHEN Age > 45 THEN 'Boomer'
			WHEN Income < 50000 OR CreditRating < 600 OR NetWorth < 100000 THEN 'MoneyAlert'
			WHEN NumberCars > 3 OR NumberCreditCards > 7 THEN 'Spender'
			WHEN Age < 25 AND NetWorth > 1000000 THEN 'Inherited'
		END AS MarketingNameplate 
	FROM [Source].[Prospect] P
GO