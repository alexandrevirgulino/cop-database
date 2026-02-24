-- Data validation checks for app.Customers (FullName, Email, StateCode)
-- Checks included: NULL/empty, duplicates, invalid emails, StateCode format

-- 1) NULL / empty checks
SELECT 'Missing FullName' AS check_name, COUNT(*) AS problem_count
FROM app.Customers
WHERE FullName IS NULL OR LTRIM(RTRIM(FullName)) = '';

SELECT 'Missing Email' AS check_name, COUNT(*) AS problem_count
FROM app.Customers
WHERE Email IS NULL OR LTRIM(RTRIM(Email)) = '';

SELECT 'Missing StateCode' AS check_name, COUNT(*) AS problem_count
FROM app.Customers
WHERE StateCode IS NULL OR LTRIM(RTRIM(StateCode)) = '';

-- StateCode format: expect 2-letter US state codes (adjust if different)
SELECT 'Invalid StateCode Format' AS check_name, COUNT(*) AS problem_count
FROM app.Customers
WHERE StateCode IS NOT NULL
	AND LTRIM(RTRIM(StateCode)) <> ''
	AND (
		LEN(LTRIM(RTRIM(StateCode))) <> 2
		OR PATINDEX('%[^A-Za-z]%', StateCode) > 0
	);

-- 2) Duplicate checks
-- Exact duplicates on FullName + Email
SELECT FullName, Email, COUNT(*) AS cnt
FROM app.Customers
GROUP BY FullName, Email
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- Potential duplicates by FullName only (different or missing emails)
SELECT FullName, COUNT(*) AS cnt
FROM app.Customers
GROUP BY FullName
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- 3) Invalid email checks
-- Basic invalid email patterns:
--  - missing '@'
--  - no '.' after the '@'
--  - contains spaces
--  - contains characters outside a conservative allowed set

-- Rows missing an '@' or a dot after the '@' or containing spaces
SELECT CustomerId, FullName, Email
FROM app.Customers
WHERE Email IS NOT NULL
	AND LTRIM(RTRIM(Email)) <> ''
	AND (
		CHARINDEX('@', Email) = 0
		OR CHARINDEX('.', Email, CHARINDEX('@', Email) + 1) = 0
		OR CHARINDEX(' ', Email) > 0
	)
ORDER BY CustomerId;

-- Rows containing characters outside a conservative allowed set
SELECT CustomerId, FullName, Email
FROM app.Customers
WHERE Email IS NOT NULL
	AND LTRIM(RTRIM(Email)) <> ''
	AND PATINDEX('%[^0-9A-Za-z@._%+-]%', Email) > 0
ORDER BY CustomerId;

-- 4) Sample problematic rows for triage (combine checks)
SELECT TOP (200) CustomerId, FullName, Email, StateCode
FROM app.Customers
WHERE
	FullName IS NULL OR LTRIM(RTRIM(FullName)) = ''
	OR Email IS NULL OR LTRIM(RTRIM(Email)) = ''
	OR StateCode IS NULL OR LTRIM(RTRIM(StateCode)) = ''
	OR CHARINDEX('@', Email) = 0
	OR CHARINDEX('.', Email, CHARINDEX('@', Email) + 1) = 0
	OR CHARINDEX(' ', Email) > 0
	OR PATINDEX('%[^0-9A-Za-z@._%+-]%', Email) > 0
	OR LEN(LTRIM(RTRIM(StateCode))) <> 2
	OR PATINDEX('%[^A-Za-z]%', StateCode) > 0
ORDER BY CustomerId;

-- Notes:
-- - For improved email-domain checks, consider adding a computed column `EmailDomain`
--   (e.g., SUBSTRING after '@') and indexing it to avoid table scans.
-- - For large tables, create appropriate indexes on (FullName, Email) and StateCode
--   or maintain deduplicated/summary tables for frequent checks.

