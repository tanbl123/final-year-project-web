-- Structured business (registered/SSM) address for suppliers.
--
-- Mirrors the structured operational (pickup) address so the verified business
-- address is captured the same way (Address line + postcode + city + state),
-- with the combined companyAddress column kept for display. Applies to BOTH the
-- live supplier row and the change-request table (the proposed values an admin
-- reviews). Existing rows keep their combined address; structured parts are NULL
-- until the supplier next saves the business address.
--
-- Apply to an existing database:
--   phpMyAdmin → shoear database → SQL → paste → Go

ALTER TABLE supplier
  ADD COLUMN companyLine1    VARCHAR(150) NULL AFTER companyAddress,
  ADD COLUMN companyPostcode VARCHAR(10)  NULL AFTER companyLine1,
  ADD COLUMN companyCity     VARCHAR(100) NULL AFTER companyPostcode,
  ADD COLUMN companyState    VARCHAR(50)  NULL AFTER companyCity;

ALTER TABLE supplier_change_request
  ADD COLUMN companyLine1    VARCHAR(150) NULL AFTER companyAddress,
  ADD COLUMN companyPostcode VARCHAR(10)  NULL AFTER companyLine1,
  ADD COLUMN companyCity     VARCHAR(100) NULL AFTER companyPostcode,
  ADD COLUMN companyState    VARCHAR(50)  NULL AFTER companyCity;
