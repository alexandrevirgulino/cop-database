-- Optimized queries and recommendations for app.Customers
-- Goal: make predicates sargable and leverage indexes instead of scans.

-- Background: Avoid using functions on columns in WHERE (e.g., RIGHT(), CAST(),
-- or leading-wildcard LIKE) because they prevent index seeks. Preferred
-- approach: add computed/persisted columns and index them, or compare using
-- the native column type.

-- Recommended schema changes (SQL Server examples):
-- 1) Add a persisted computed column for email domain and index it (one-time):
-- ALTER TABLE app.Customers
-- ADD EmailDomain AS LOWER(SUBSTRING(Email, CHARINDEX('@', Email) + 1, 8000)) PERSISTED;
-- CREATE INDEX IX_Customers_EmailDomain ON app.Customers(EmailDomain);

-- 2) Index StateCode if filtered/aggregated often:
-- CREATE INDEX IX_Customers_StateCode ON app.Customers(StateCode);

-- Query rewrites

-- 1) Problematic: RIGHT(Email, 11) = '@example.com' (non-sargable)
-- Fast (with computed column):
SELECT CustomerId, FullName, Email, StateCode
FROM app.Customers
WHERE EmailDomain = 'example.com';

-- Fallback if you cannot change schema (will scan):
SELECT CustomerId, FullName, Email
FROM app.Customers
WHERE Email LIKE '%@example.com';

-- 2) Problematic: Email LIKE '%@example.com' (leading wildcard)
-- Same fix: use EmailDomain
SELECT CustomerId, FullName, Email
FROM app.Customers
WHERE EmailDomain = 'example.com';

-- 3) Problematic: CAST(StateCode AS CHAR(2)) = 2
-- Casting the column (or mismatched literal) prevents index seeks. Compare using native type.
-- If StateCode is INT:
SELECT COUNT_BIG(*) AS cnt
FROM app.Customers
WHERE StateCode = 2;

-- If StateCode is stored as text, compare to the correct text literal (avoid casting the column):
-- SELECT COUNT_BIG(*) FROM app.Customers WHERE StateCode = '02';

-- Additional performance tips:
-- - Use covering indexes to avoid lookups for frequently-run queries.
--   Example: CREATE INDEX IX_Customers_EmailDomain_COVER ON app.Customers(EmailDomain) INCLUDE (CustomerId, FullName, Email);
-- - For very large datasets, consider maintaining aggregated counters or a summary table
--   for heavy-count queries rather than scanning the base table repeatedly.
-- - Use filtered indexes for skewed predicates (e.g., WHERE StateCode = 2) when appropriate.
