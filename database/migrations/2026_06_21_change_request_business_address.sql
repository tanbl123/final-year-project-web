-- Business address becomes a VERIFIED identity field.
-- The registered business address matches the SSM document, so (like the company
-- name and SSM number) it can no longer be edited freely after approval — it now
-- goes through the supplier_change_request re-approval flow. The freely-editable
-- address is the operational (pickup) address instead.
--
-- Add the proposed-value column to the change-request table. Existing pending
-- rows (if any) get an empty placeholder; new requests always supply it.

ALTER TABLE supplier_change_request
  ADD COLUMN companyAddress VARCHAR(255) NOT NULL DEFAULT '' AFTER companyName;

ALTER TABLE supplier_change_request
  ALTER COLUMN companyAddress DROP DEFAULT;
