-- Supplier re-registration / resubmission flow.
--
-- Real marketplaces split a registration "rejection" into two outcomes:
--   * Rejected  — curable. The application is kept and the supplier is told
--                 what to fix; they edit and resubmit (status → Pending again).
--   * Banned    — terminal. Fraud/policy; the identity may not re-apply.
--
-- We already retained the user + supplier rows on rejection; this adds the
-- 'Banned' status and a reason the supplier can see when fixing their details.

ALTER TABLE `user`
  MODIFY COLUMN status
    ENUM('Pending','Active','Rejected','Banned','Suspended','Deleted')
    NOT NULL DEFAULT 'Pending';

ALTER TABLE `user`
  ADD COLUMN rejectionReason VARCHAR(255) NULL AFTER status;
