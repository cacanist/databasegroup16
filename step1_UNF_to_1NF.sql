-- ============================================================
--  CSE 204 Spring 2026 – GROUP 16
--  STEP 1: UNF  →  1NF
-- ============================================================
--
--  What makes the UNF table violate 1NF?
--  ─────────────────────────────────────
--  A table is in 1NF when:
--    (a) every cell holds one atomic value (no sets or lists),
--    (b) there are no repeating column groups,
--    (c) every row is uniquely identified by a primary key.
--
--  Violation found — repeating column groups:
--    The UNF table stores three page-category pairs side by side:
--      Administrative  / Administrative_Duration
--      Informational   / Informational_Duration
--      ProductRelated  / ProductRelated_Duration
--    These three groups all describe the same concept (page category,
--    page count, time spent) but are spread across six separate columns.
--    That is a classic repeating-group violation.
--
--  Fix applied:
--    Extract the repeating groups into a child table PAGE_ACTIVITY_1NF
--    with its own (Session_Id, Page_Category) composite primary key.
--    All other columns remain in SESSION_1NF with Session_Id as PK.
--    The two tables are linked by the Session_Id foreign key.
--
--  Result after this step:
--    ┌─────────────────┐           ┌──────────────────────┐
--    │  SESSION_1NF    │  1 ──── * │  PAGE_ACTIVITY_1NF   │
--    │  PK: Session_Id │           │  PK: Session_Id,     │
--    │  (29 columns)   │           │      Page_Category   │
--    └─────────────────┘           └──────────────────────┘
--
--  Note: Transitive and partial dependencies still exist in
--  SESSION_1NF and will be resolved in subsequent steps.
-- ============================================================


-- ============================================================
-- STEP 0: DROP & RECREATE STAGING TABLE (35 columns)
-- ============================================================

DROP TABLE IF EXISTS unnormalized_shoppers;

CREATE TABLE unnormalized_shoppers (
    Session_Id              INT,
    Administrative          INT,
    Administrative_Duration DOUBLE,
    Informational           INT,
    Informational_Duration  DOUBLE,
    ProductRelated          INT,
    ProductRelated_Duration DOUBLE,
    BounceRates             DOUBLE,
    ExitRates               DOUBLE,
    PageValues              DOUBLE,
    SpecialDay              DOUBLE,
    Month                   VARCHAR(20),
    OperatingSystems        INT,
    Browser                 INT,
    Region                  INT,
    TrafficType             INT,
    VisitorType             VARCHAR(50),
    Weekend                 TINYINT,
    Revenue                 TINYINT,
    Country                 VARCHAR(50),
    Age_Group               VARCHAR(20),
    Language                VARCHAR(50),
    AccountCreated          VARCHAR(50),
    LastSeen                VARCHAR(50),
    BrowserVersion          VARCHAR(50),
    DeviceType              VARCHAR(50),
    ScreenResolution        VARCHAR(50),
    JavaEnabled             VARCHAR(10),
    HourOfDay               INT,
    Quarter                 INT,
    IsHoliday               VARCHAR(10),
    SessionDuration         DOUBLE,
    SuggestedBy             VARCHAR(50),
    ConversionRate          DOUBLE,
    EngagementScore         DOUBLE
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/unnormalized_shoppers_expanded_clean.csv'
INTO TABLE unnormalized_shoppers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 1NF TABLE 1: SESSION_1NF
--   The main session record; repeating groups removed.
--   All remaining columns depend on Session_Id.
--   (Transitive/partial dependencies not yet resolved.)
-- ============================================================

DROP TABLE IF EXISTS SESSION_1NF;

CREATE TABLE SESSION_1NF (
    Session_Id       INT            PRIMARY KEY,
    -- Analytics metrics (fully depend on the session)
    BounceRates      DOUBLE,
    ExitRates        DOUBLE,
    PageValues       DOUBLE,
    ConversionRate   DOUBLE,
    EngagementScore  DOUBLE,
    -- Temporal context
    SpecialDay       DOUBLE,
    Month            VARCHAR(20),
    Weekend          TINYINT,
    HourOfDay        INT,
    Quarter          INT,
    IsHoliday        VARCHAR(10),
    -- Device / browser config
    OperatingSystems INT,
    Browser          INT,
    BrowserVersion   VARCHAR(50),
    DeviceType       VARCHAR(50),
    ScreenResolution VARCHAR(50),
    JavaEnabled      VARCHAR(10),
    -- Visitor identity
    Region           INT,
    Country          VARCHAR(50),
    VisitorType      VARCHAR(50),
    Age_Group        VARCHAR(20),
    Language         VARCHAR(50),
    AccountCreated   VARCHAR(50),
    LastSeen         VARCHAR(50),
    -- Session facts
    TrafficType      INT,
    Revenue          TINYINT,
    SessionDuration  DOUBLE,
    SuggestedBy      VARCHAR(50)
);

INSERT INTO SESSION_1NF
SELECT
    Session_Id,
    BounceRates, ExitRates, PageValues, ConversionRate, EngagementScore,
    SpecialDay, Month, Weekend, HourOfDay, Quarter, IsHoliday,
    OperatingSystems, Browser, BrowserVersion, DeviceType, ScreenResolution, JavaEnabled,
    Region, Country, VisitorType, Age_Group, Language, AccountCreated, LastSeen,
    TrafficType, Revenue, SessionDuration, SuggestedBy
FROM unnormalized_shoppers;


-- ============================================================
-- 1NF TABLE 2: PAGE_ACTIVITY_1NF
--   The three repeating column groups are unpivoted into rows.
--   Each row represents one (session, page-category) pair.
--   Composite PK: (Session_Id, Page_Category).
-- ============================================================

DROP TABLE IF EXISTS PAGE_ACTIVITY_1NF;

CREATE TABLE PAGE_ACTIVITY_1NF (
    Session_Id    INT          NOT NULL,
    Page_Category VARCHAR(50)  NOT NULL,
    Page_Count    INT,
    Duration      DOUBLE,
    PRIMARY KEY (Session_Id, Page_Category),
    FOREIGN KEY (Session_Id) REFERENCES SESSION_1NF(Session_Id)
);

-- Unpivot the three repeating groups into individual rows
INSERT INTO PAGE_ACTIVITY_1NF (Session_Id, Page_Category, Page_Count, Duration)
SELECT Session_Id, 'Administrative', Administrative, Administrative_Duration
FROM unnormalized_shoppers
UNION ALL
SELECT Session_Id, 'Informational',  Informational,  Informational_Duration
FROM unnormalized_shoppers
UNION ALL
SELECT Session_Id, 'ProductRelated', ProductRelated, ProductRelated_Duration
FROM unnormalized_shoppers;


-- ============================================================
-- CLEANUP: remove repeating-group columns from staging table
--   (these are now fully represented in PAGE_ACTIVITY_1NF)
-- ============================================================

ALTER TABLE unnormalized_shoppers DROP COLUMN Administrative;
ALTER TABLE unnormalized_shoppers DROP COLUMN Administrative_Duration;
ALTER TABLE unnormalized_shoppers DROP COLUMN Informational;
ALTER TABLE unnormalized_shoppers DROP COLUMN Informational_Duration;
ALTER TABLE unnormalized_shoppers DROP COLUMN ProductRelated;
ALTER TABLE unnormalized_shoppers DROP COLUMN ProductRelated_Duration;


-- ============================================================
-- VERIFICATION
-- ============================================================

-- Row count in SESSION_1NF should equal original row count
SELECT COUNT(*) AS session_rows FROM SESSION_1NF;

-- PAGE_ACTIVITY_1NF should have exactly 3× the session count
-- (one row per category per session)
SELECT COUNT(*) AS activity_rows FROM PAGE_ACTIVITY_1NF;

-- Spot-check: every session should have exactly 3 category rows
SELECT Session_Id, COUNT(*) AS category_count
FROM PAGE_ACTIVITY_1NF
GROUP BY Session_Id
HAVING category_count <> 3;   -- should return 0 rows
