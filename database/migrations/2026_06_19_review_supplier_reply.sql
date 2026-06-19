-- Supplier reply to a product review (one public reply per review), like the
-- seller responses on Shopee/Lazada/Amazon. Suppliers can add, edit and delete
-- their own reply; they can never edit or delete the customer's review itself.
--
-- Apply to an existing database:
--   phpMyAdmin → shoear database → SQL → paste → Go

ALTER TABLE review
  ADD COLUMN supplierReply     TEXT     NULL AFTER reviewStatus,
  ADD COLUMN supplierReplyDate DATETIME NULL AFTER supplierReply;
