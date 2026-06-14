-- Direct bank-account details for supplier payouts.
--
-- The project collects the supplier's bank account directly (instead of, or
-- alongside, Stripe Connect onboarding). Suppliers manage these from their
-- profile page; admins/finance use them to pay out sales income.

ALTER TABLE supplier
  ADD COLUMN bankName          VARCHAR(100) NULL AFTER taxNumber,
  ADD COLUMN bankAccountName   VARCHAR(150) NULL AFTER bankName,
  ADD COLUMN bankAccountNumber VARCHAR(34)  NULL AFTER bankAccountName;
