-- Step 1: Nullify SuggestedBy for sessions that credit this visitor
UPDATE SESSION
SET SuggestedBy = NULL
WHERE SuggestedBy = 1;

-- Step 2: Remove page visits for sessions owned by this visitor
DELETE FROM PAGE_VISIT
WHERE Session_ID IN (SELECT Session_ID FROM SESSION WHERE Visitor_ID = 1);

-- Step 3: Remove analytics metrics
DELETE FROM ANALYTICS_METRICS
WHERE Session_ID IN (SELECT Session_ID FROM SESSION WHERE Visitor_ID = 1);

-- Step 4: Remove page activity records
DELETE FROM PAGE_ACTIVITY
WHERE Session_ID IN (SELECT Session_ID FROM SESSION WHERE Visitor_ID = 1);

-- Step 5: Remove the visitor's sessions
DELETE FROM SESSION
WHERE Visitor_ID = 1;

-- Step 6: Remove suggestions where this visitor was suggester or receiver
DELETE FROM SUGGESTION
WHERE Suggester_Visitor = 1 OR Receiver_Visitor = 1;

-- Step 7: Remove the visitor record itself
DELETE FROM VISITOR
WHERE Visitor_ID = 1;