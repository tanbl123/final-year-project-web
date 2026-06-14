-- Supplier payouts via Stripe Connect (Stage 2 direction change).
-- Bank details are no longer stored locally — Stripe Connect collects and
-- verifies the supplier's bank account during hosted onboarding. We keep only
-- a reference to their Connect account and whether payouts are enabled.

ALTER TABLE supplier
  DROP COLUMN bankName,
  DROP COLUMN bankAccountName,
  DROP COLUMN bankAccountNo,
  ADD COLUMN stripeAccountId VARCHAR(60) NULL          AFTER taxNumber,
  ADD COLUMN payoutsEnabled  TINYINT(1)  NOT NULL DEFAULT 0 AFTER stripeAccountId;
