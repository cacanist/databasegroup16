SELECT
    tc.Month,
    mi.Quarter,
    COUNT(DISTINCT s.Visitor_ID) AS Visitor_Count
FROM TIME_CONTEXT tc
JOIN MONTH_INFO mi ON  tc.Month   = mi.Month
JOIN SESSION    s  ON  tc.Time_ID = s.Time_ID
GROUP BY tc.Month, mi.Quarter
ORDER BY Visitor_Count DESC;