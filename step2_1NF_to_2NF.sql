-- ============================================================
--  CSE 204 Spring 2026 – GROUP 16
--  STEP 2: 1NF  →  2NF
-- ============================================================
--
--  What makes SESSION_1NF violate 2NF?
--  ─────────────────────────────────────
--  A table is in 2NF when it is in 1NF AND every non-key
--  attribute is fully functionally dependent on the ENTIRE
--  primary key (no partial dependencies).
--
--  SESSION_1NF has a single-column PK (Session_Id), so by
--  definition there cannot be partial key dependencies on
--  Session_Id itself. However, 2NF is also the natural stage
--  to separate concerns: many non-key attributes in SESSION_1NF
--  don't actually describe the session — they describe the
--  visitor, the device config, or the time context. These
--  attributes repeat across many session rows, which means the
--  same fact is stored redundantly (update anomalies).
--
--  Groups of attributes that belong together (not to SESSION):
--
--    VISITOR group — describe the person, not the session:
--      VisitorType, Region, Country, Age_Group, Language,
--      AccountCreated, LastSeen
--
--    SYSTEM_CONFIG group — describe the device/browser:
--      OperatingSystems, Browser, BrowserVersion,
--      DeviceType, ScreenResolution, JavaEnabled
--
--    TIME_CONTEXT group — describe the time window:
--      Month, SpecialDay, Weekend, HourOfDay, Quarter, IsHoliday
--
--    ANALYTICS_METRICS group — session quality metrics:
--      BounceRates, ExitRates, PageValues,
--      ConversionRate, EngagementScore
--
--  Fix applied:
--    Each group is extracted into its own table with a
--    surrogate PK. SESSION_2NF replaces the raw attribute
--    columns with FK references to those tables.
--
--  Result after this step:
--    ┌──────────────────┐
--    │   VISITOR_2NF    │◄──────────────────────────────────┐
--    │   PK: Visitor_ID │                                   │
--    └──────────────────┘                                   │
--    ┌──────────────────┐                                   │
--    │ SYSTEM_CONFIG_2NF│◄──────────┐                       │
--    │   PK: Config_ID  │           │                       │
--    └──────────────────┘           │                       │
--    ┌──────────────────┐           │                       │
--    │ TIME_CONTEXT_2NF │◄──┐       │   ┌──────────────────┐│
--    │   PK: Time_ID    │   │       │   │   SESSION_2NF    ││
--    └──────────────────┘   └───────┴───│  PK: Session_ID  │┘
--                                       │  FK: Visitor_ID  │
--    ┌──────────────────┐               │  FK: Config_ID   │
--    │ANALYTICS_METR_2NF│◄──────────────│  FK: Time_ID     │
--    │  PK: Metric_ID   │               └──────────────────┘
--    └──────────────────┘
--
--  PAGE_ACTIVITY_1NF is carried forward unchanged as
--  PAGE_ACTIVITY_2NF (its structure is already correct).
--
--  Note: Transitive dependencies within VISITOR_2NF,
--  SYSTEM_CONFIG_2NF and TIME_CONTEXT_2NF still exist
--  and will be resolved in step 3.
-- ============================================================


-- ============================================================
-- PREREQUISITE: tables from step 1 must already exist.
--   SESSION_1NF, PAGE_ACTIVITY_1NF
-- ============================================================


-- ============================================================
-- 2NF TABLE 1: VISITOR_2NF
--   Holds visitor identity attributes.
--   Unique key: (VisitorType, Region, Country, Age_Group, Language)
--   Note: Region -> Country is a transitive dependency —
--         it will be removed in step 3.
-- ============================================================

DROP TABLE IF EXISTS VISITOR_2NF;

CREATE TABLE VISITOR_2NF (
    Visitor_ID     INT AUTO_INCREMENT PRIMARY KEY,
    VisitorType    VARCHAR(50),
    Region         INT,
    Country        VARCHAR(100),   -- transitive via Region; removed in step 3
    Age_Group      VARCHAR(20),
    Language       VARCHAR(30),
    AccountCreated DATE,
    LastSeen       DATETIME
);

INSERT INTO VISITOR_2NF (VisitorType, Region, Country, Age_Group, Language, AccountCreated, LastSeen)
SELECT DISTINCT
    VisitorType,
    Region,
    Country,
    Age_Group,
    Language,
    STR_TO_DATE(AccountCreated, '%Y-%m-%d'),
    STR_TO_DATE(LastSeen,       '%Y-%m-%d %H:%i:%s')
FROM SESSION_1NF;


-- ============================================================
-- 2NF TABLE 2: SYSTEM_CONFIG_2NF
--   Holds device and browser environment attributes.
--   Note: Browser -> BrowserVersion is a transitive dependency
--         — it will be removed in step 3.
-- ============================================================

DROP TABLE IF EXISTS SYSTEM_CONFIG_2NF;

CREATE TABLE SYSTEM_CONFIG_2NF (
    Config_ID        INT AUTO_INCREMENT PRIMARY KEY,
    OperatingSystems INT,
    Browser          INT,
    BrowserVersion   VARCHAR(30),   -- transitive via Browser; removed in step 3
    DeviceType       VARCHAR(20),
    ScreenResolution VARCHAR(20),
    JavaEnabled      BOOLEAN
);

INSERT INTO SYSTEM_CONFIG_2NF (OperatingSystems, Browser, BrowserVersion, DeviceType, ScreenResolution, JavaEnabled)
SELECT DISTINCT
    OperatingSystems,
    Browser,
    BrowserVersion,
    DeviceType,
    ScreenResolution,
    IF(LOWER(JavaEnabled) = 'true', 1, 0)
FROM SESSION_1NF;


-- ============================================================
-- 2NF TABLE 3: TIME_CONTEXT_2NF
--   Holds temporal attributes for the session.
--   Note: Month -> Quarter is a transitive dependency
--         — it will be removed in step 3.
-- ============================================================

DROP TABLE IF EXISTS TIME_CONTEXT_2NF;

CREATE TABLE TIME_CONTEXT_2NF (
    Time_ID    INT AUTO_INCREMENT PRIMARY KEY,
    Month      VARCHAR(20),
    SpecialDay DOUBLE,
    Weekend    BOOLEAN,
    HourOfDay  INT,
    Quarter    INT,      -- transitive via Month; removed in step 3
    IsHoliday  BOOLEAN
);

INSERT INTO TIME_CONTEXT_2NF (Month, SpecialDay, Weekend, HourOfDay, Quarter, IsHoliday)
SELECT DISTINCT
    Month,
    SpecialDay,
    CAST(Weekend AS UNSIGNED),
    HourOfDay,
    Quarter,
    IF(LOWER(IsHoliday) = 'true', 1, 0)
FROM SESSION_1NF;


-- ============================================================
-- 2NF TABLE 4: SESSION_2NF
--   Central fact table. Each row is one session.
--   All columns either ARE the PK or describe this specific
--   session (TrafficType, Revenue, SessionDuration, SuggestedBy).
--   Visitor/config/time data is replaced with FK references.
-- ============================================================

DROP TABLE IF EXISTS SESSION_2NF;

CREATE TABLE SESSION_2NF (
    Session_ID      INT PRIMARY KEY,
    Visitor_ID      INT,
    Config_ID       INT,
    Time_ID         INT,
    TrafficType     INT,
    Revenue         BOOLEAN,
    SessionDuration DOUBLE,
    SuggestedBy     INT,    -- FK to VISITOR_2NF; NULL = organic visit
    FOREIGN KEY (Visitor_ID)  REFERENCES VISITOR_2NF(Visitor_ID),
    FOREIGN KEY (Config_ID)   REFERENCES SYSTEM_CONFIG_2NF(Config_ID),
    FOREIGN KEY (Time_ID)     REFERENCES TIME_CONTEXT_2NF(Time_ID),
    FOREIGN KEY (SuggestedBy) REFERENCES VISITOR_2NF(Visitor_ID)
);

INSERT INTO SESSION_2NF (Session_ID, Visitor_ID, Config_ID, Time_ID, TrafficType, Revenue, SessionDuration, SuggestedBy)
SELECT
    s.Session_Id,
    v.Visitor_ID,
    c.Config_ID,
    t.Time_ID,
    s.TrafficType,
    CAST(s.Revenue AS UNSIGNED),
    s.SessionDuration,
    NULLIF(s.SuggestedBy, '')  -- blank string → NULL for FK integrity
FROM SESSION_1NF s
JOIN VISITOR_2NF v
    ON  s.VisitorType  = v.VisitorType
    AND s.Region       = v.Region
    AND s.Country      = v.Country
    AND s.Age_Group    = v.Age_Group
    AND s.Language     = v.Language
JOIN SYSTEM_CONFIG_2NF c
    ON  s.OperatingSystems = c.OperatingSystems
    AND s.Browser          = c.Browser
    AND s.DeviceType       = c.DeviceType
JOIN TIME_CONTEXT_2NF t
    ON  s.Month      = t.Month
    AND s.SpecialDay = t.SpecialDay
    AND s.HourOfDay  = t.HourOfDay;


-- ============================================================
-- 2NF TABLE 5: ANALYTICS_METRICS_2NF
--   Session quality metrics. Each attribute depends fully
--   on Session_ID — no transitive dependencies exist here.
-- ============================================================

DROP TABLE IF EXISTS ANALYTICS_METRICS_2NF;

CREATE TABLE ANALYTICS_METRICS_2NF (
    Metric_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Session_ID      INT,
    BounceRates     DOUBLE,
    ExitRates       DOUBLE,
    PageValues      DOUBLE,
    ConversionRate  DOUBLE,
    EngagementScore DOUBLE,
    FOREIGN KEY (Session_ID) REFERENCES SESSION_2NF(Session_ID)
);

INSERT INTO ANALYTICS_METRICS_2NF (Session_ID, BounceRates, ExitRates, PageValues, ConversionRate, EngagementScore)
SELECT Session_Id, BounceRates, ExitRates, PageValues, ConversionRate, EngagementScore
FROM SESSION_1NF;


-- ============================================================
-- 2NF TABLE 6: PAGE_ACTIVITY_2NF
--   Carried forward from 1NF; FK updated to SESSION_2NF.
--   No structural change required.
-- ============================================================

DROP TABLE IF EXISTS PAGE_ACTIVITY_2NF;

CREATE TABLE PAGE_ACTIVITY_2NF (
    Activity_ID   INT AUTO_INCREMENT PRIMARY KEY,
    Session_ID    INT,
    Page_Category VARCHAR(50),
    Page_Count    INT,
    Duration      DOUBLE,
    FOREIGN KEY (Session_ID) REFERENCES SESSION_2NF(Session_ID)
);

INSERT INTO PAGE_ACTIVITY_2NF (Session_ID, Page_Category, Page_Count, Duration)
SELECT Session_Id, Page_Category, Page_Count, Duration
FROM PAGE_ACTIVITY_1NF;


-- ============================================================
-- VERIFICATION
-- ============================================================

-- Session count must be preserved
SELECT COUNT(*) AS session_2nf_rows  FROM SESSION_2NF;

-- Every session must resolve to exactly one visitor, config, time
SELECT COUNT(*) AS unmatched_sessions
FROM SESSION_1NF s
LEFT JOIN VISITOR_2NF      v ON s.VisitorType = v.VisitorType AND s.Region = v.Region
                             AND s.Country = v.Country AND s.Age_Group = v.Age_Group
                             AND s.Language = v.Language
WHERE v.Visitor_ID IS NULL;   -- should return 0

-- Dimension table sizes
SELECT 'VISITOR_2NF'       AS tbl, COUNT(*) AS row_count FROM VISITOR_2NF
UNION ALL
SELECT 'SYSTEM_CONFIG_2NF',        COUNT(*) FROM SYSTEM_CONFIG_2NF
UNION ALL
SELECT 'TIME_CONTEXT_2NF',         COUNT(*) FROM TIME_CONTEXT_2NF
UNION ALL
SELECT 'ANALYTICS_METRICS_2NF',    COUNT(*) FROM ANALYTICS_METRICS_2NF
UNION ALL
SELECT 'PAGE_ACTIVITY_2NF',        COUNT(*) FROM PAGE_ACTIVITY_2NF;
