-- Structured operational (pickup) address for suppliers.
--
-- The pickup address now drives delivery routing (in-house local courier vs
-- standard 3PL shipping when the supplier and customer are in different states),
-- so it needs a structured STATE (and postcode/city) rather than one free-text
-- line. This mirrors the structured customer/order address (migration
-- 2026_06_25) so the whole platform collects Malaysian addresses the same way.
--
-- The original combined column (supplier.operationalAddress) is KEPT and stays
-- the single-line value every existing screen prints (admin, courier pickup,
-- etc.). New/edited suppliers populate BOTH the structured parts (source of
-- truth) and the combined line. Existing rows keep their combined address; the
-- structured columns are NULL until the supplier next edits their pickup address.
--
-- The registered business address (companyAddress) is a VERIFIED field on the
-- change-request flow and is intentionally left untouched here.
--
-- Apply to an existing database:
--   phpMyAdmin → shoear database → SQL → paste → Go

ALTER TABLE supplier
  ADD COLUMN operationalLine1    VARCHAR(150) NULL AFTER operationalAddress,
  ADD COLUMN operationalLine2    VARCHAR(150) NULL AFTER operationalLine1,
  ADD COLUMN operationalPostcode VARCHAR(10)  NULL AFTER operationalLine2,
  ADD COLUMN operationalCity     VARCHAR(100) NULL AFTER operationalPostcode,
  ADD COLUMN operationalState    VARCHAR(50)  NULL AFTER operationalCity;
