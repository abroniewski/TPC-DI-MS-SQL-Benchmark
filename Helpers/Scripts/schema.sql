DROP DATABASE IF EXISTS TPC_DI_DB;
GO

CREATE DATABASE TPC_DI_DB;
GO

USE TPC_DI_DB;
GO

-- TPC DI Staging Area

CREATE SCHEMA Source;
GO

CREATE TABLE Source.Account (
	-- CDC_FLAG CHAR(1),
	-- CDC_DSN NUMERIC(12),
	CA_ID NUMERIC(11),
	CA_B_ID NUMERIC(11),
	CA_C_ID NUMERIC(11),
	CA_NAME CHAR(50),
	CA_TAX_ST NUMERIC(1),
	CA_ST_ID CHAR(4)
)

CREATE TABLE Source.BatchDate (
	BatchDate DATE
)

CREATE TABLE Source.CashTransaction (
	-- CDC_FLAG CHAR(1),
	-- CDC_DSN NUMERIC(12),
	CT_CA_ID NUMERIC(11),
	CT_DTS DATETIME,
	CT_AMT NUMERIC(10,2),
	CT_NAME CHAR(100)
)

CREATE TABLE Source.Customer (
	-- CDC_FLAG CHAR(1),
	-- CDC_DSN NUMERIC(12),
	C_ID NUMERIC(11),
	C_TAX_ID CHAR(20),
	C_ST_ID CHAR(4),
	C_L_NAME CHAR(25),
	C_F_NAME CHAR(20),
	C_M_NAME CHAR(1),
	C_GNDR CHAR(1),
	C_TIER NUMERIC(1),
	C_DOB DATE,
	C_ADLINE1 CHAR(80),
	C_ADLINE2 CHAR(80),
	C_ZIPCODE CHAR(12),
	C_CITY CHAR(25),
	C_STATE_PROV CHAR(20),
	C_CTRY CHAR(24),
	C_CTRY_1 CHAR(3),
	C_AREA_1 CHAR(3),
	C_LOCAL_1 CHAR(10),
	C_EXT_1 CHAR(5),
	C_CTRY_2 CHAR(3),
	C_AREA_2 CHAR(3),
	C_LOCAL_2 CHAR(10),
	C_EXT_2 CHAR(5),
	C_CTRY_3 CHAR(3),
	C_AREA_3 CHAR(3),
	C_LOCAL_3 CHAR(10),
	C_EXT_3 CHAR(5),
	C_EMAIL_1 CHAR(50),
	C_EMAIL_2 CHAR(50),
	C_LCL_TX_ID CHAR(4),
	C_NAT_TX_ID CHAR(4)
)

CREATE TABLE Source.ActionXML (
	ActionType NVARCHAR(9),
	ActionTS NVARCHAR(256),
	Action_Id NVARCHAR(256),
)

CREATE TABLE Source.CustomerXML (
	C_ID NUMERIC(11),
	C_TAX_ID NVARCHAR(20),
	C_GNDR NVARCHAR(1),
	C_TIER NVARCHAR(256), -- Should be NUMERIC(1)
	C_DOB DATE,
    Customer_Id NVARCHAR(256),
    Action_Id NVARCHAR(256),
)

CREATE TABLE Source.NameXML (
	C_L_NAME NVARCHAR(25),
	C_F_NAME NVARCHAR(20),
	C_M_NAME NVARCHAR(1),
	Customer_Id NVARCHAR(256),
)

CREATE TABLE Source.AddressXML (
	C_ADLINE1 NVARCHAR(80),
	C_ADLINE2 NVARCHAR(80),
	C_ZIPCODE NVARCHAR(12),
	C_CITY NVARCHAR(25),
	C_STATE_PROV NVARCHAR(20),
	C_CTRY NVARCHAR(24),
	Customer_Id NVARCHAR(256),
)

CREATE TABLE Source.ContactInfoXML (
	C_PRIM_EMAIL NVARCHAR(50),
	C_ALT_EMAIL NVARCHAR(50),
	Customer_Id NVARCHAR(256),
	ContactInfo_Id NVARCHAR(256),
)

CREATE TABLE Source.C_PHONE_1_XML (
	C_CTRY_CODE NVARCHAR(3),
	C_AREA_CODE NVARCHAR(3),
	C_LOCAL NVARCHAR(10),
	C_EXT NVARCHAR(5) ,
	ContactInfo_Id NVARCHAR(256),
)

CREATE TABLE Source.C_PHONE_2_XML (
	C_CTRY_CODE NVARCHAR(3),
	C_AREA_CODE NVARCHAR(3),
	C_LOCAL NVARCHAR(10),
	C_EXT NVARCHAR(5),
	ContactInfo_Id NVARCHAR(256),
)

CREATE TABLE Source.C_PHONE_3_XML (
	C_CTRY_CODE NVARCHAR(3),
	C_AREA_CODE NVARCHAR(3),
	C_LOCAL NVARCHAR(10),
	C_EXT NVARCHAR(5),
	ContactInfo_Id NVARCHAR(256),
)

CREATE TABLE Source.TaxInfoXML (
	C_LCL_TX_ID NVARCHAR(4),
	C_NAT_TX_ID NVARCHAR(4),
    Customer_Id NVARCHAR(256),
)

CREATE TABLE Source.AccountXML (
	CA_ID NUMERIC(11),
	CA_TAX_ST NUMERIC(1),
	CA_B_ID NUMERIC(11),
	CA_NAME NVARCHAR(50),
    Customer_Id NVARCHAR(256),
)

CREATE TABLE Source.DailyMarket (
    -- CDC_FLAG CHAR(1),
    -- CDC_DSN NUMERIC(12),
    DM_DATE DATE,
    DM_S_SYMB CHAR(15),
    DM_CLOSE NUMERIC(8,2),
    DM_HIGH NUMERIC(8,2),
    DM_LOW NUMERIC(8,2),
    DM_VOL NUMERIC(12),
);

CREATE TABLE Source.Date (
    SK_DateID NUMERIC(11),
    DateValue CHAR(20),
    DateDesc CHAR(20),
    CalendarYearID NUMERIC(4),
    CalendarYearDesc CHAR(20),
    CalendarQtrID NUMERIC(5),
    CalendarQtrDesc CHAR(20),
    CalendarMonthID NUMERIC(6),
    CalendarMonthDesc CHAR(20),
    CalendarWeekID NUMERIC(6),
    CalendarWeekDesc CHAR(20),
    DayOfWeekNum NUMERIC(1),
    DayOfWeekDesc CHAR(10),
    FiscalYearID NUMERIC(4),
    FiscalYearDesc CHAR(20),
    FiscalQtrID NUMERIC(5),
    FiscalQtrDesc CHAR(20),
    HolidayFlag NVARCHAR(5), -- This is supposed to be a '0' or '1' but it is 'true' or 'false'
)

CREATE TABLE Source.FinwireCMP (
    PTS NVARCHAR(256),
    RecType NVARCHAR(256),
    CompanyName NVARCHAR(256),
    CIK NVARCHAR(256),
    Status NVARCHAR(256),
    IndustryID NVARCHAR(256),
    SPrating NVARCHAR(256),
    FoundingDate NVARCHAR(256),
    AddrLine1 NVARCHAR(256),
    AddrLine2 NVARCHAR(256),
    PostalCode NVARCHAR(256),
    City NVARCHAR(256),
    StateProvince NVARCHAR(256),
    Country NVARCHAR(256),
    CEOname NVARCHAR(256),
    Description NVARCHAR(256),
);

CREATE TABLE Source.FinwireSEC (
    PTS NVARCHAR(256),
    RecType NVARCHAR(256),
    Symbol NVARCHAR(256),
    IssueType NVARCHAR(256),
    Status NVARCHAR(256),
    Name NVARCHAR(256),
    ExID NVARCHAR(256),
    ShOut NVARCHAR(256),
    FirstTradeDate NVARCHAR(256),
    FirstTradeExchg NVARCHAR(256),
    Dividend NVARCHAR(256),
    CoNameOrCIK NVARCHAR(256),
);

CREATE TABLE Source.FinwireFIN (
    PTS NVARCHAR(256),
    RecType NVARCHAR(256),
    Year NVARCHAR(256),
    Quarter NVARCHAR(256),
    QtrStartDate NVARCHAR(256),
    PostingDate NVARCHAR(256),
    Revenue NVARCHAR(256),
    Earnings NVARCHAR(256),
    EPS NVARCHAR(256),
    DilutedEPS NVARCHAR(256),
    Margin NVARCHAR(256),
    Inventory NVARCHAR(256),
    Assets NVARCHAR(256),
    Liabilities NVARCHAR(256),
    ShOut NVARCHAR(256),
    DilutedShOut NVARCHAR(256),
    CoNameOrCIK NVARCHAR(256),
);

CREATE TABLE Source.HoldingHistory (
    -- CDC_FLAG CHAR(1),
    -- CDC_DSN NUMERIC(12),
    HH_H_T_ID NUMERIC(15),
    HH_T_ID NUMERIC(15),
    HH_BEFORE_QTY NUMERIC(6),
    HH_AFTER_QTY NUMERIC(6),
);

CREATE TABLE Source.HR (
    EmployeeID NUMERIC(11),
    ManagerID NUMERIC(11),
    EmployeeFirstName CHAR(30),
    EmployeeLastName CHAR(30),
    EmployeeMI CHAR(1),
    EmployeeJobCode NUMERIC(3),
    EmployeeBranch CHAR(30),
    EmployeeOffice CHAR(10),
    EmployeePhone CHAR(14),
);

CREATE TABLE Source.Industry (
    IN_ID CHAR(2),
    IN_NAME CHAR(50),
    IN_SC_ID CHAR(4),
);

CREATE TABLE Source.Prospect (
    AgencyID CHAR(30),
    LastName CHAR(30),
    FirstName CHAR(30),
    MiddleInitial CHAR(1),
    Gender CHAR(1),
    AddressLine1 CHAR(80),
    AddressLine2 CHAR(80),
    PostalCode CHAR(12),
    City CHAR(25),
    State CHAR(20),
    Country CHAR(24),
    Phone CHAR(30),
    Income NUMERIC(9),
    NumberCars NUMERIC(2),
    NumberChildren NUMERIC(2),
    MaritalStatus CHAR(1),
    Age NUMERIC(3),
    CreditRating NUMERIC(4),
    OwnOrRentFlag CHAR(1),
    Employer CHAR(30),
    NumberCreditCards NUMERIC(2),
    NetWorth NUMERIC(12)
);


CREATE TABLE Source.StatusType (
    ST_ID CHAR(4),
    ST_NAME CHAR(10),
);


CREATE TABLE Source.TaxRate (
    TX_ID CHAR(4),
    TX_NAME CHAR(50),
    TX_RATE NUMERIC(6,5),
);

CREATE TABLE Source.Time (
    SK_TimeID NUMERIC(11),
    TimeValue CHAR(20),
    HourID NUMERIC(2),
    HourDesc CHAR(20),
    MinuteID NUMERIC(2),
    MinuteDesc CHAR(20),
    SecondID NUMERIC(2),
    SecondDesc CHAR(20),
    MarketHoursFlag NVARCHAR(5), -- This is supposed to be a '0' or '1' but it is 'true' or 'false'
    OfficeHoursFlag NVARCHAR(5), -- This is supposed to be a '0' or '1' but it is 'true' or 'false'
);

CREATE TABLE Source.TradeHistory (
    TH_T_ID NUMERIC(15),
    TH_DTS DATETIME,
    TH_ST_ID CHAR(4),
);

CREATE TABLE Source.Trade (
    -- CDC_FLAG CHAR(1),
    -- CDC_DSN NUMERIC(12),
    T_ID NUMERIC(15),
    T_DTS DATETIME,
    T_ST_ID CHAR(4),
    T_TT_ID CHAR(3),
    T_IS_CASH NVARCHAR(5), -- This is supposed to be a '0' or '1' but it is 'true' or 'false'
    T_S_SYMB CHAR(15),
    T_QTY NUMERIC(6),
    T_BID_PRICE NUMERIC(8,2),
    T_CA_ID NUMERIC(11),
    T_EXEC_NAME CHAR(49),
    T_TRADE_PRICE NUMERIC(8,2),
    T_CHRG NUMERIC(10,2),
    T_COMM NUMERIC(10,2),
    T_TAX NUMERIC(10,2),
);

CREATE TABLE Source.TradeType (
    TT_ID CHAR(3),
    TT_NAME CHAR(12),
    TT_IS_SELL NUMERIC(1),
    TT_IS_MRKT NUMERIC(1)
);


CREATE TABLE Source.WatchHistory (
    -- CDC_FLAG CHAR(1),
    -- CDC_DSN NUMERIC(12),
    W_C_ID NUMERIC(11),
    W_S_SYMB CHAR(15),
    W_DTS DATETIME,
    W_ACTION CHAR(4)
);

CREATE TABLE Source.AuditFiles (
    DataSet CHAR(20),
    BatchID NUMERIC(5),
    Date DATE,
    Attribute CHAR(50),
    Value NUMERIC(15),
    DValue NUMERIC(15,5)
);


-- TPC DI Data Warehouse

-- Original SQL Script pulled from TPC-DI Project completed by:
-- Gonçalo Moreira, Nazrin Najafzade, Rémy Detobel, Shafagh Kashef
-- https://github.com/detobel36/tpc-di/blob/master/createTables.sql

-- Code has been reviewed and checked against TPC-DI_SPEC_v1.1.0.pdf

-- Meta Types are not being used (e.g. SK_T is a NUM(11). NUM does not exist in SQL server, use CHAR()?)
-- why is there space between column name and type for status an accountDesc?
-- is creating including the restrictions (e.g. CHAR(50) or NOT NULL) the referential integrity
--  we were talking about potentially not including?
-- is it just sloppy scripting to have Not NULL vs NOT NULL?
-- numeric(5) vs integer vs char(5) etc.

CREATE TABLE DimBroker  (
    SK_BrokerID  INTEGER NOT NULL IDENTITY (1,1) PRIMARY KEY,
    BrokerID  INTEGER NOT NULL,
    ManagerID  INTEGER,
    FirstName       CHAR(50) NOT NULL,
    LastName       CHAR(50) NOT NULL,
    MiddleInitial       CHAR(1),
    Branch       CHAR(50),
    Office       CHAR(50),
    Phone       CHAR(14),
    IsCurrent BIT NOT NULL,
    BatchID INTEGER NOT NULL,
    EffectiveDate date NOT NULL,
    EndDate date NOT NULL                                                 
);

CREATE TABLE DimCompany (
    SK_CompanyID INTEGER NOT NULL IDENTITY (1,1) PRIMARY KEY, 
    CompanyID INTEGER NOT NULL,
    Status CHAR(10) Not NULL, 
    Name CHAR(60) Not NULL,
    Industry CHAR(50) Not NULL,
    SPrating CHAR(4),
    isLowGrade BIT,
    CEO CHAR(100) Not NULL,
    AddressLine1 CHAR(80),
    AddressLine2 CHAR(80),
    PostalCode CHAR(12) Not NULL,
    City CHAR(25) Not NULL,
    StateProv CHAR(20) Not NULL,
    Country CHAR(24),
    Description CHAR(150) Not NULL,
    FoundingDate DATE,
    IsCurrent BIT Not NULL,
    BatchID numeric(5) Not NULL,
    EffectiveDate DATE Not NULL,
    EndDate DATE Not NULL
);

CREATE TABLE DimCustomer  (
    SK_CustomerID  INTEGER NOT NULL IDENTITY (1,1) PRIMARY KEY,
    CustomerID INTEGER NOT NULL,
    TaxID CHAR(20) NOT NULL,
    Status CHAR(10) NOT NULL,
    LastName CHAR(30) NOT NULL,
    FirstName CHAR(30) NOT NULL,
    MiddleInitial CHAR(1),
    Gender CHAR(1),
    Tier Integer,
    DOB date NOT NULL,
    AddressLine1  varchar(80) NOT NULL,
    AddressLine2  varchar(80),
    PostalCode    char(12) NOT NULL,
    City   char(25) NOT NULL,
    StateProv     char(20) NOT NULL,
    Country       char(24),
    Phone1 char(30),
    Phone2 char(30),
    Phone3 char(30),
    Email1 char(50),
    Email2 char(50),
    NationalTaxRateDesc  varchar(50),
    NationalTaxRate      numeric(6,5),
    LocalTaxRateDesc     varchar(50),
    LocalTaxRate  numeric(6,5),
    AgencyID      char(30),
    CreditRating integer,
    NetWorth      numeric(10),
    MarketingNameplate varchar(100),
    IsCurrent BIT NOT NULL,
    BatchID INTEGER NOT NULL,
    EffectiveDate date NOT NULL,
    EndDate date NOT NULL
);

CREATE TABLE DimAccount  (
    SK_AccountID  INTEGER NOT NULL IDENTITY (1,1) PRIMARY KEY,
    AccountID  INTEGER NOT NULL,
    SK_BrokerID  INTEGER NOT NULL REFERENCES DimBroker (SK_BrokerID),
    SK_CustomerID  INTEGER NOT NULL REFERENCES DimCustomer (SK_CustomerID),
    Status       CHAR(10) NOT NULL,
    AccountDesc       varchar(50),
    TaxStatus  INTEGER NOT NULL CHECK (TaxStatus = 0 OR TaxStatus = 1 OR TaxStatus = 2),
    IsCurrent BIT NOT NULL,
    BatchID INTEGER NOT NULL,
    EffectiveDate date NOT NULL,
    EndDate date NOT NULL
);

CREATE TABLE DimDate (
    SK_DateID INTEGER Not NULL PRIMARY KEY,
    DateValue DATE Not NULL,
    DateDesc CHAR(20) Not NULL,
    CalendarYearID numeric(4) Not NULL,
    CalendarYearDesc CHAR(20) Not NULL,
    CalendarQtrID numeric(5) Not NULL,
    CalendarQtrDesc CHAR(20) Not NULL,
    CalendarMonthID numeric(6) Not NULL,
    CalendarMonthDesc CHAR(20) Not NULL,
    CalendarWeekID numeric(6) Not NULL,
    CalendarWeekDesc CHAR(20) Not NULL,
    DayOfWeeknumeric numeric(1) Not NULL,
    DayOfWeekDesc CHAR(10) Not NULL,
    FiscalYearID numeric(4) Not NULL,
    FiscalYearDesc CHAR(20) Not NULL,
    FiscalQtrID numeric(5) Not NULL,
    FiscalQtrDesc CHAR(20) Not NULL,
    HolidayFlag BIT
);

CREATE TABLE DimSecurity(
    SK_SecurityID INTEGER Not NULL IDENTITY (1,1) PRIMARY KEY,
    Symbol CHAR(15) Not NULL,
    Issue CHAR(6) Not NULL,
    Status CHAR(10) Not NULL,
    Name CHAR(70) Not NULL,
    ExchangeID CHAR(6) Not NULL,
    SK_CompanyID INTEGER Not NULL REFERENCES DimCompany (SK_CompanyID),
    SharesOutstanding INTEGER Not NULL,
    FirstTrade DATE Not NULL,
    FirstTradeOnExchange DATE Not NULL,
    Dividend numeric(10,2) Not NULL,
    IsCurrent BIT Not NULL,
    BatchID numeric(5) Not NULL,
    EffectiveDate DATE Not NULL,
    EndDate DATE Not NULL
);

CREATE TABLE DimTime (
    SK_TimeID INTEGER Not NULL PRIMARY KEY,
    TimeValue TIME Not NULL,
    HourID numeric(2) Not NULL,
    HourDesc CHAR(20) Not NULL,
    MinuteID numeric(2) Not NULL,
    MinuteDesc CHAR(20) Not NULL,
    SecondID numeric(2) Not NULL,
    SecondDesc CHAR(20) Not NULL,
    MarketHoursFlag BIT,
    OfficeHoursFlag BIT
);

CREATE TABLE DimTrade (
    TradeID INTEGER Not NULL,
    SK_BrokerID INTEGER REFERENCES DimBroker (SK_BrokerID),
    SK_CreateDateID INTEGER REFERENCES DimDate (SK_DateID),
    SK_CreateTimeID INTEGER REFERENCES DimTime (SK_TimeID),
    SK_CloseDateID INTEGER REFERENCES DimDate (SK_DateID),
    SK_CloseTimeID INTEGER REFERENCES DimTime (SK_TimeID),
    Status CHAR(10) Not NULL,
    DT_Type CHAR(12) Not NULL,
    CashFlag BIT Not NULL,
    SK_SecurityID INTEGER Not NULL REFERENCES DimSecurity (SK_SecurityID),
    SK_CompanyID INTEGER Not NULL REFERENCES DimCompany (SK_CompanyID),
    Quantity numeric(6,0) Not NULL,
    BidPrice numeric(8,2) Not NULL,
    SK_CustomerID INTEGER Not NULL REFERENCES DimCustomer (SK_CustomerID),
    SK_AccountID INTEGER Not NULL REFERENCES DimAccount (SK_AccountID),
    ExecutedBy CHAR(64) Not NULL,
    TradePrice numeric(8,2),
    Fee numeric(10,2),
    Commission numeric(10,2),
    Tax numeric(10,2),
    BatchID numeric(5) Not Null
);

CREATE TABLE DImessages (
    MessageDateAndTime TIMESTAMP Not NULL,
    BatchID numeric(5) Not NULL,
    MessageSource CHAR(30),
    MessageText CHAR(50) Not NULL,
    MessageType CHAR(12) Not NULL,
    MessageData CHAR(100)
);

CREATE TABLE FactCashBalances (
    SK_CustomerID INTEGER Not Null REFERENCES DimCustomer (SK_CustomerID),
    SK_AccountID INTEGER Not Null REFERENCES DimAccount (SK_AccountID),
    SK_DateID INTEGER Not Null REFERENCES DimDate (SK_DateID),
    Cash numeric(15,2) Not Null,
    BatchID numeric(5)
);

CREATE TABLE FactHoldings (
    TradeID INTEGER Not NULL,
    CurrentTradeID INTEGER Not Null,
    SK_CustomerID INTEGER Not NULL REFERENCES DimCustomer (SK_CustomerID),
    SK_AccountID INTEGER Not NULL REFERENCES DimAccount (SK_AccountID),
    SK_SecurityID INTEGER Not NULL REFERENCES DimSecurity (SK_SecurityID),
    SK_CompanyID INTEGER Not NULL REFERENCES DimCompany (SK_CompanyID),
    SK_DateID INTEGER NULL REFERENCES DimDate (SK_DateID),
    SK_TimeID INTEGER NULL REFERENCES DimTime (SK_TimeID),
    CurrentPrice numeric(8,2) CHECK (CurrentPrice > 0) ,
    CurrentHolding numeric(6) Not NULL,
    BatchID numeric(5)
);

CREATE TABLE FactMarketHistory (   
    SK_SecurityID INTEGER Not Null REFERENCES DimSecurity (SK_SecurityID),
    SK_CompanyID INTEGER Not Null REFERENCES DimCompany (SK_CompanyID),
    SK_DateID INTEGER Not Null REFERENCES DimDate (SK_DateID),
    PERatio numeric(10,2),
    Yield numeric(5,2) Not Null,
    FiftyTwoWeekHigh numeric(8,2) Not Null,
    SK_FiftyTwoWeekHighDate INTEGER Not Null,
    FiftyTwoWeekLow numeric(8,2) Not Null,
    SK_FiftyTwoWeekLowDate INTEGER Not Null,
    ClosePrice numeric(8,2) Not Null,
    DayHigh numeric(8,2) Not Null,
    DayLow numeric(8,2) Not Null,
    Volume numeric(12) Not Null,
    BatchID numeric(5)
);

CREATE TABLE FactWatches (
    SK_CustomerID INTEGER Not NULL REFERENCES DimCustomer (SK_CustomerID),
    SK_SecurityID INTEGER Not NULL REFERENCES DimSecurity (SK_SecurityID),
    SK_DateID_DatePlaced INTEGER Not NULL REFERENCES DimDate (SK_DateID),
    SK_DateID_DateRemoved INTEGER REFERENCES DimDate (SK_DateID),
    BatchID numeric(5) Not Null 
);

CREATE TABLE Industry (
    IN_ID CHAR(2) Not NULL,
    IN_NAME CHAR(50) Not NULL,
    IN_SC_ID CHAR(4) Not NULL
);

CREATE TABLE Financial (
    SK_CompanyID INTEGER Not NULL REFERENCES DimCompany (SK_CompanyID),
    FI_YEAR numeric(4) Not NULL,
    FI_QTR numeric(1) Not NULL,
    FI_QTR_START_DATE DATE Not NULL,
    FI_REVENUE numeric(15,2) Not NULL,
    FI_NET_EARN numeric(15,2) Not NULL,
    FI_BASIC_EPS numeric(10,2) Not NULL,
    FI_DILUT_EPS numeric(10,2) Not NULL,
    FI_MARGIN numeric(10,2) Not NULL,
    FI_INVENTORY numeric(15,2) Not NULL,
    FI_ASSETS numeric(15,2) Not NULL,
    FI_LIABILITY numeric(15,2) Not NULL,
    FI_OUT_BASIC numeric(12) Not NULL,
    FI_OUT_DILUT numeric(12) Not NULL
);

CREATE TABLE Prospect (
    AgencyID CHAR(30) NOT NULL UNIQUE,  
    SK_RecordDateID INTEGER NOT NULL, 
    SK_UpdateDateID INTEGER NOT NULL REFERENCES DimDate (SK_DateID),
    BatchID numeric(5) NOT NULL,
    IsCustomer BIT NOT NULL,
    LastName CHAR(30) NOT NULL,
    FirstName CHAR(30) NOT NULL,
    MiddleInitial CHAR(1),
    Gender CHAR(1),
    AddressLine1 CHAR(80),
    AddressLine2 CHAR(80),
    PostalCode CHAR(12),
    City CHAR(25) NOT NULL,
    State CHAR(20) NOT NULL,
    Country CHAR(24),
    Phone CHAR(30), 
    Income numeric(9),
    numberCars numeric(2), 
    numberChildren numeric(2), 
    MaritalStatus CHAR(1), 
    Age numeric(3),
    CreditRating numeric(4),
    OwnOrRentFlag CHAR(1), 
    Employer CHAR(30),
    numberCreditCards numeric(2), 
    NetWorth numeric(12),
    MarketingNameplate CHAR(100)
);

CREATE TABLE StatusType (
    ST_ID CHAR(4) Not NULL,
    ST_NAME CHAR(10) Not NULL
);

CREATE TABLE TaxRate (
    TX_ID CHAR(4) Not NULL,
    TX_NAME CHAR(50) Not NULL,
    TX_RATE numeric(6,5) Not NULL
);

CREATE TABLE TradeType (
    TT_ID CHAR(3) Not NULL,
    TT_NAME CHAR(12) Not NULL,
    TT_IS_SELL numeric(1) Not NULL,
    TT_IS_MRKT numeric(1) Not NULL
);

CREATE TABLE AuditTable (
    DataSet CHAR(20) Not Null,
    BatchID numeric(5),
    AT_Date DATE,
    AT_Attribute CHAR(50),
    AT_Value numeric(15),
    DValue numeric(15,5)
);

CREATE INDEX PIndex ON DimTrade (TradeID);