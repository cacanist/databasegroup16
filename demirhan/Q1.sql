SELECT
    v.Visitor_ID,
    v.VisitorType,
    cr.Region_ID,
    v.Country,
    bi.Browser_ID       AS Browser,
    bi.BrowserVersion
FROM VISITOR v
JOIN  COUNTRY_REGION    cr ON  v.Country     = cr.Country
LEFT JOIN SESSION       s  ON  v.Visitor_ID  = s.Visitor_ID
LEFT JOIN SYSTEM_CONFIG sc ON  s.Config_ID   = sc.Config_ID
LEFT JOIN BROWSER_INFO  bi ON  sc.Browser_ID = bi.Browser_ID
ORDER BY v.Visitor_ID;