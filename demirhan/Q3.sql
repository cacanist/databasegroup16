-- The new country value must already exist in the COUNTRY_REGION table.
UPDATE VISITOR
SET Country = 'Japan'
WHERE Visitor_ID = 1;