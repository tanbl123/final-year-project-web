-- Distinguish automatic monthly payouts from manual ones, so the monthly sweep
-- can tell whether it has already run this calendar month.
ALTER TABLE courier_payout
  ADD COLUMN isAuto TINYINT(1) NOT NULL DEFAULT 0 AFTER payoutStatus;
