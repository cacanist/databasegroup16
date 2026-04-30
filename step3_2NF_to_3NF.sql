-- ============================================================
--  CSE 204 Spring 2026 – GROUP 16
--  STEP 3: 2NF  →  3NF
-- ============================================================
--
--  What makes the 2NF tables violate 3NF?
--  ─────────────────────────────────────
--  A table is in 3NF when it is in 2NF AND no non-key attribute
--  is transitively dependent on the primary key.
--  A transitive dependency exists when:
--    PK → A → B   (B depends on A, not directly on PK)
--
--  Three transitive dependencies were found across the 2NF tables:
--
--  1. In VISITOR_2NF:
--       Visitor_ID → Country → Region
--     Region is a property of the Country, not directly of the visitor.
--     (e.g., knowing the country is Japan guarantees it is Region 7, 
--     but Region 7 has multiple countries). 
--     Fix: extract COUNTRY_REGION(Country, Region_ID) with Country as PK, 
--     and replace Region in VISITOR with Country as a FK.
--
--  2. In SYSTEM_CONFIG_2NF:
--       Config_ID → Browser → BrowserVersion
--     BrowserVersion is a property of the Browser product, not of
--     a specific device configuration. Fix: extract
--     BROWSER(Browser_ID, BrowserVersion) and keep Browser as FK.
--
--  3. In TIME_CONTEXT_2NF:
--       Time_ID → Month → Quarter
--     Quarter is derived from Month — it does not independently
--     describe a session's time context. Fix: extract
--     MONTH_INFO(Month, Quarter) with Month as PK (it is already
--     a natural unique identifier) and remove Quarter from
--     TIME_CONTEXT.
--
--  All other tables (SESSION, ANALYTICS_METRICS, PAGE_ACTIVITY)
--  have no transitive dependencies and are promoted unchanged.
--
--  New tables added in this step (already in 3NF by design):
--    PAGE        — master catalogue of pages visitors can view
--    PAGE_VISIT  — individual page visit events per session
--    SUGGESTION  — page suggestions between visitors
--
--  Final schema (3NF):
--    ┌──────────┐   ┌──────────┐   ┌────────────────┐
--    │  REGION  │──▶│ VISITOR  │   │  MONTH_INFO    │
--    └──────────┘   └────┬─────┘   │  PK: Month     │
--    ┌──────────┐        │         └───────┬────────┘
--    │ BROWSER  │◄──┐    │                 │
--    └──────────┘   │    │    ┌────────────┴───┐
--    ┌──────────┐   │    │    │ TIME_CONTEXT   │
--    │SYS_CONFIG│───┘    │    └────────┬───────┘
--    └──────────┘        │             │
--                   ┌────┴─────────────┴───┐
--                   │      SESSION         │
--                   └──────────┬───────────┘
--             ┌────────────────┼──────────────────┐
--    ┌─────────┴──────┐ ┌──────┴──────┐ ┌────────┴───────┐
--    │ANALYTICS_METR. │ │PAGE_ACTIVITY│ │   PAGE_VISIT   │
--    └────────────────┘ └─────────────┘ └────────┬───────┘
--                                                 │
--                                            ┌────┴──┐
--                                            │  PAGE │
--                                            └───────┘
--    ┌────────────────────────────────────────────────┐
--    │  SUGGESTION  (Visitor → Page → Visitor)        │
--    └────────────────────────────────────────────────┘
-- ============================================================


-- ============================================================
-- PREREQUISITE: tables from step 2 must already exist:
--   VISITOR_2NF, SYSTEM_CONFIG_2NF, TIME_CONTEXT_2NF,
--   SESSION_2NF, ANALYTICS_METRICS_2NF, PAGE_ACTIVITY_2NF
-- ============================================================


-- ============================================================
-- FIX 1: VISITOR_2NF  →  COUNTRY_REGION + VISITOR
--
--  Transitive removed:  Visitor_ID → Country → Region
--
--  COUNTRY_REGION holds Country → Region_ID.
--  VISITOR now references Country as FK instead of storing
--  Region directly.
-- ============================================================

DROP TABLE IF EXISTS COUNTRY_REGION;

CREATE TABLE COUNTRY_REGION (
    Country    VARCHAR(100) PRIMARY KEY,
    Region_ID  INT NOT NULL
);

INSERT INTO COUNTRY_REGION (Country, Region_ID)
SELECT DISTINCT Country, Region
FROM VISITOR_2NF;

-- VISITOR: Region column dropped; Country stays as FK to COUNTRY_REGION
DROP TABLE IF EXISTS VISITOR;

CREATE TABLE VISITOR (
    Visitor_ID     INT AUTO_INCREMENT PRIMARY KEY,
    VisitorType    VARCHAR(50),
    Country        VARCHAR(100),  -- FK → COUNTRY_REGION (replaces the direct Region column)
    Age_Group      VARCHAR(20),
    Language       VARCHAR(30),
    AccountCreated DATE,
    LastSeen       DATETIME,
    FOREIGN KEY (Country) REFERENCES COUNTRY_REGION(Country)
);

INSERT INTO VISITOR (Visitor_ID, VisitorType, Country, Age_Group, Language, AccountCreated, LastSeen)
SELECT Visitor_ID, VisitorType, Country, Age_Group, Language, AccountCreated, LastSeen
FROM VISITOR_2NF;


-- ============================================================
-- FIX 2: SYSTEM_CONFIG_2NF  →  BROWSER_INFO + SYSTEM_CONFIG
--
--  Transitive removed:  Config_ID → Browser → BrowserVersion
--
--  BROWSER_INFO holds Browser → BrowserVersion.
--  SYSTEM_CONFIG keeps Browser as FK instead of repeating
--  BrowserVersion on every config row.
-- ============================================================

DROP TABLE IF EXISTS BROWSER_INFO;

CREATE TABLE BROWSER_INFO (
    Browser_ID     INT PRIMARY KEY,    -- natural key (matches Browser integers)
    BrowserVersion VARCHAR(30)
);

INSERT INTO BROWSER_INFO (Browser_ID, BrowserVersion)
SELECT DISTINCT Browser, BrowserVersion
FROM SYSTEM_CONFIG_2NF;

-- SYSTEM_CONFIG: BrowserVersion column dropped
DROP TABLE IF EXISTS SYSTEM_CONFIG;

CREATE TABLE SYSTEM_CONFIG (
    Config_ID        INT AUTO_INCREMENT PRIMARY KEY,
    OperatingSystems INT,
    Browser_ID       INT,           -- FK → BROWSER_INFO
    DeviceType       VARCHAR(20),
    ScreenResolution VARCHAR(20),
    JavaEnabled      BOOLEAN,
    FOREIGN KEY (Browser_ID) REFERENCES BROWSER_INFO(Browser_ID)
);

INSERT INTO SYSTEM_CONFIG (Config_ID, OperatingSystems, Browser_ID, DeviceType, ScreenResolution, JavaEnabled)
SELECT Config_ID, OperatingSystems, Browser, DeviceType, ScreenResolution, JavaEnabled
FROM SYSTEM_CONFIG_2NF;


-- ============================================================
-- FIX 3: TIME_CONTEXT_2NF  →  MONTH_INFO + TIME_CONTEXT
--
--  Transitive removed:  Time_ID → Month → Quarter
--
--  MONTH_INFO holds Month → Quarter.
--  TIME_CONTEXT keeps Month as an FK instead of repeating
--  Quarter on every time-context row.
-- ============================================================

DROP TABLE IF EXISTS MONTH_INFO;

CREATE TABLE MONTH_INFO (
    Month   VARCHAR(20) PRIMARY KEY,   -- natural key ('Jan'..'Dec')
    Quarter INT
);

INSERT INTO MONTH_INFO (Month, Quarter)
SELECT DISTINCT Month, Quarter
FROM TIME_CONTEXT_2NF;

-- TIME_CONTEXT: Quarter column dropped
DROP TABLE IF EXISTS TIME_CONTEXT;

CREATE TABLE TIME_CONTEXT (
    Time_ID    INT AUTO_INCREMENT PRIMARY KEY,
    Month      VARCHAR(20),      -- FK → MONTH_INFO
    SpecialDay DOUBLE,
    Weekend    BOOLEAN,
    HourOfDay  INT,
    IsHoliday  BOOLEAN,
    FOREIGN KEY (Month) REFERENCES MONTH_INFO(Month)
);

INSERT INTO TIME_CONTEXT (Time_ID, Month, SpecialDay, Weekend, HourOfDay, IsHoliday)
SELECT Time_ID, Month, SpecialDay, Weekend, HourOfDay, IsHoliday
FROM TIME_CONTEXT_2NF;


-- ============================================================
-- PROMOTE SESSION (no structural change needed)
--   SESSION_2NF is already in 3NF — all non-key columns
--   (TrafficType, Revenue, SessionDuration, SuggestedBy) depend
--   directly and only on Session_ID. Rename and update FKs.
-- ============================================================

DROP TABLE IF EXISTS SESSION;

CREATE TABLE SESSION (
    Session_ID      INT PRIMARY KEY,
    Visitor_ID      INT,
    Config_ID       INT,
    Time_ID         INT,
    TrafficType     INT,
    Revenue         BOOLEAN,
    SessionDuration DOUBLE,
    SuggestedBy     INT,    -- FK to VISITOR; NULL = organic visit
    FOREIGN KEY (Visitor_ID)  REFERENCES VISITOR(Visitor_ID),
    FOREIGN KEY (Config_ID)   REFERENCES SYSTEM_CONFIG(Config_ID),
    FOREIGN KEY (Time_ID)     REFERENCES TIME_CONTEXT(Time_ID),
    FOREIGN KEY (SuggestedBy) REFERENCES VISITOR(Visitor_ID)
);

INSERT INTO SESSION
SELECT * FROM SESSION_2NF;


-- ============================================================
-- PROMOTE ANALYTICS_METRICS (no structural change needed)
-- ============================================================

DROP TABLE IF EXISTS ANALYTICS_METRICS;

CREATE TABLE ANALYTICS_METRICS (
    Metric_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Session_ID      INT,
    BounceRates     DOUBLE,
    ExitRates       DOUBLE,
    PageValues      DOUBLE,
    ConversionRate  DOUBLE,
    EngagementScore DOUBLE,
    FOREIGN KEY (Session_ID) REFERENCES SESSION(Session_ID)
);

INSERT INTO ANALYTICS_METRICS (Session_ID, BounceRates, ExitRates, PageValues, ConversionRate, EngagementScore)
SELECT Session_ID, BounceRates, ExitRates, PageValues, ConversionRate, EngagementScore
FROM ANALYTICS_METRICS_2NF;


-- ============================================================
-- PROMOTE PAGE_ACTIVITY (no structural change needed)
-- ============================================================

DROP TABLE IF EXISTS PAGE_ACTIVITY;

CREATE TABLE PAGE_ACTIVITY (
    Activity_ID   INT AUTO_INCREMENT PRIMARY KEY,
    Session_ID    INT,
    Page_Category VARCHAR(50),
    Page_Count    INT,
    Duration      DOUBLE,
    FOREIGN KEY (Session_ID) REFERENCES SESSION(Session_ID)
);

INSERT INTO PAGE_ACTIVITY (Session_ID, Page_Category, Page_Count, Duration)
SELECT Session_ID, Page_Category, Page_Count, Duration
FROM PAGE_ACTIVITY_2NF;


-- ============================================================
-- NEW: PAGE  (3NF by design — all attrs depend only on Page_ID)
-- ============================================================

DROP TABLE IF EXISTS PAGE;

CREATE TABLE PAGE (
    Page_ID         INT AUTO_INCREMENT PRIMARY KEY,
    Page_URL        VARCHAR(500),
    Page_Title      VARCHAR(200),
    Page_Category   VARCHAR(50),
    LoadTime_Avg    DOUBLE,
    DatePublished   DATE
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/PAGE.csv'
INTO TABLE PAGE
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Page_ID, Page_URL, Page_Title, Page_Category, LoadTime_Avg, @dp)
SET DatePublished = STR_TO_DATE(@dp, '%Y-%m-%d');


-- ============================================================
-- NEW: PAGE_VISIT  (3NF by design)
-- ============================================================

DROP TABLE IF EXISTS PAGE_VISIT;

CREATE TABLE PAGE_VISIT (
    Visit_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Session_ID     INT,
    Page_ID        INT,
    VisitTimestamp DATETIME,
    TimeOnPage     DOUBLE,
    ScrollDepth    INT,
    Referrer_URL   VARCHAR(500),
    FOREIGN KEY (Session_ID) REFERENCES SESSION(Session_ID),
    FOREIGN KEY (Page_ID)    REFERENCES PAGE(Page_ID)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/PAGE_VISIT.csv'
INTO TABLE PAGE_VISIT
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Visit_ID, Session_ID, Page_ID, @vts, TimeOnPage, ScrollDepth, Referrer_URL)
SET VisitTimestamp = STR_TO_DATE(@vts, '%Y-%m-%d %H:%i:%s');


-- ============================================================
-- NEW: SUGGESTION  (3NF by design)
-- ============================================================

DROP TABLE IF EXISTS SUGGESTION;

CREATE TABLE SUGGESTION (
    Suggestion_ID     INT AUTO_INCREMENT PRIMARY KEY,
    Suggester_Visitor INT,
    Receiver_Visitor  INT,
    Page_ID           INT,
    Suggestion_Date   DATETIME,
    Was_Visited       BOOLEAN,
    FOREIGN KEY (Suggester_Visitor) REFERENCES VISITOR(Visitor_ID),
    FOREIGN KEY (Receiver_Visitor)  REFERENCES VISITOR(Visitor_ID),
    FOREIGN KEY (Page_ID)           REFERENCES PAGE(Page_ID)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/SUGGESTION.csv'
INTO TABLE SUGGESTION
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Suggestion_ID, Suggester_Visitor, Receiver_Visitor, Page_ID, @sd, @wv)
SET Suggestion_Date = STR_TO_DATE(@sd, '%Y-%m-%d %H:%i:%s'),
    Was_Visited     = IF(LOWER(@wv) = 'true', 1, 0);


-- ============================================================
-- ALTER TABLE: DROP STAGING COLUMNS
--   Remove the original 18 UNF columns from unnormalized_shoppers
--   now that all data lives in normalized 3NF tables.
-- ============================================================

ALTER TABLE unnormalized_shoppers DROP COLUMN BounceRates;
ALTER TABLE unnormalized_shoppers DROP COLUMN ExitRates;
ALTER TABLE unnormalized_shoppers DROP COLUMN PageValues;
ALTER TABLE unnormalized_shoppers DROP COLUMN SpecialDay;
ALTER TABLE unnormalized_shoppers DROP COLUMN Month;
ALTER TABLE unnormalized_shoppers DROP COLUMN OperatingSystems;
ALTER TABLE unnormalized_shoppers DROP COLUMN Browser;
ALTER TABLE unnormalized_shoppers DROP COLUMN Region;
ALTER TABLE unnormalized_shoppers DROP COLUMN TrafficType;
ALTER TABLE unnormalized_shoppers DROP COLUMN VisitorType;
ALTER TABLE unnormalized_shoppers DROP COLUMN Weekend;
ALTER TABLE unnormalized_shoppers DROP COLUMN Revenue;
ALTER TABLE unnormalized_shoppers DROP COLUMN Country;
ALTER TABLE unnormalized_shoppers DROP COLUMN Age_Group;
ALTER TABLE unnormalized_shoppers DROP COLUMN Language;
ALTER TABLE unnormalized_shoppers DROP COLUMN AccountCreated;
ALTER TABLE unnormalized_shoppers DROP COLUMN LastSeen;
ALTER TABLE unnormalized_shoppers DROP COLUMN BrowserVersion;


-- ============================================================
-- RECONSTRUCTED VIEW  (same output as original UNF table)
-- ============================================================

CREATE VIEW Reconstructed_UNF AS
SELECT
    pa_admin.Page_Count     AS Administrative,
    pa_admin.Duration       AS Administrative_Duration,
    pa_info.Page_Count      AS Informational,
    pa_info.Duration        AS Informational_Duration,
    pa_prod.Page_Count      AS ProductRelated,
    pa_prod.Duration        AS ProductRelated_Duration,
    am.BounceRates,
    am.ExitRates,
    am.PageValues,
    tc.SpecialDay,
    tc.Month,
    sc.OperatingSystems,
    bi.Browser_ID           AS Browser,
    cr.Region_ID             AS Region,
    s.TrafficType,
    v.VisitorType,
    tc.Weekend,
    s.Revenue
FROM SESSION s
JOIN VISITOR            v        ON s.Visitor_ID  = v.Visitor_ID
JOIN COUNTRY_REGION     cr       ON v.Country     = cr.Country
JOIN SYSTEM_CONFIG      sc       ON s.Config_ID   = sc.Config_ID
JOIN BROWSER_INFO       bi       ON sc.Browser_ID = bi.Browser_ID
JOIN TIME_CONTEXT       tc       ON s.Time_ID     = tc.Time_ID
JOIN ANALYTICS_METRICS  am       ON s.Session_ID  = am.Session_ID
JOIN PAGE_ACTIVITY      pa_admin ON s.Session_ID  = pa_admin.Session_ID AND pa_admin.Page_Category = 'Administrative'
JOIN PAGE_ACTIVITY      pa_info  ON s.Session_ID  = pa_info.Session_ID  AND pa_info.Page_Category  = 'Informational'
JOIN PAGE_ACTIVITY      pa_prod  ON s.Session_ID  = pa_prod.Session_ID  AND pa_prod.Page_Category  = 'ProductRelated';

SELECT * FROM Reconstructed_UNF;


-- ============================================================
-- USER INTERFACE QUERIES
-- ============================================================

-- UI 1: List all visitors and the browser(s) used by each
SELECT
    v.Visitor_ID,
    v.VisitorType,
    cr.Region_ID,
    v.Country,
    bi.Browser_ID       AS Browser,
    bi.BrowserVersion
FROM VISITOR v
JOIN COUNTRY_REGION     cr ON v.Country     = cr.Country
JOIN SESSION            s  ON v.Visitor_ID  = s.Visitor_ID
JOIN SYSTEM_CONFIG      sc ON s.Config_ID   = sc.Config_ID
JOIN BROWSER_INFO       bi ON sc.Browser_ID = bi.Browser_ID
ORDER BY v.Visitor_ID;

-- UI 2: List each month and the number of visitors seen in that month
SELECT
    tc.Month,
    mi.Quarter,
    COUNT(DISTINCT s.Visitor_ID) AS Visitor_Count
FROM TIME_CONTEXT tc
JOIN MONTH_INFO mi ON tc.Month   = mi.Month
JOIN SESSION    s  ON tc.Time_ID = s.Time_ID
GROUP BY tc.Month, mi.Quarter
ORDER BY Visitor_Count DESC;

-- UI 3: Change the country for a visitor (which inherently changes their region)
--   Replace the values as needed
UPDATE VISITOR
SET Country = 'Japan'
WHERE Visitor_ID = 105;

-- UI 4: Add a new page visit
INSERT INTO PAGE_VISIT (Session_ID, Page_ID, VisitTimestamp, TimeOnPage)
VALUES (250, 14, NOW(), 120.5);

-- UI 5: Remove a visitor from the database (correct dependency order)
DELETE FROM PAGE_VISIT        WHERE Session_ID IN (SELECT Session_ID FROM SESSION WHERE Visitor_ID = 42);
DELETE FROM ANALYTICS_METRICS WHERE Session_ID IN (SELECT Session_ID FROM SESSION WHERE Visitor_ID = 42);
DELETE FROM PAGE_ACTIVITY     WHERE Session_ID IN (SELECT Session_ID FROM SESSION WHERE Visitor_ID = 42);
DELETE FROM SESSION           WHERE Visitor_ID = 42;
DELETE FROM SUGGESTION        WHERE Suggester_Visitor = 42 OR Receiver_Visitor = 42;
DELETE FROM VISITOR           WHERE Visitor_ID = 42;


-- ============================================================
-- FINAL VERIFICATION
-- ============================================================

-- All tables should have data
SELECT 'COUNTRY_REGION'    AS tbl, COUNT(*) AS row_count FROM COUNTRY_REGION
UNION ALL SELECT 'BROWSER_INFO',              COUNT(*) FROM BROWSER_INFO
UNION ALL SELECT 'MONTH_INFO',                COUNT(*) FROM MONTH_INFO
UNION ALL SELECT 'VISITOR',                   COUNT(*) FROM VISITOR
UNION ALL SELECT 'SYSTEM_CONFIG',             COUNT(*) FROM SYSTEM_CONFIG
UNION ALL SELECT 'TIME_CONTEXT',              COUNT(*) FROM TIME_CONTEXT
UNION ALL SELECT 'SESSION',                   COUNT(*) FROM SESSION
UNION ALL SELECT 'ANALYTICS_METRICS',         COUNT(*) FROM ANALYTICS_METRICS
UNION ALL SELECT 'PAGE_ACTIVITY',             COUNT(*) FROM PAGE_ACTIVITY
UNION ALL SELECT 'PAGE',                      COUNT(*) FROM PAGE
UNION ALL SELECT 'PAGE_VISIT',                COUNT(*) FROM PAGE_VISIT
UNION ALL SELECT 'SUGGESTION',                COUNT(*) FROM SUGGESTION;

-- Reconstructed view should match original session count
SELECT COUNT(*) AS reconstructed_rows FROM Reconstructed_UNF;
