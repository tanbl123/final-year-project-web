-- Split fulfilment: one delivery per supplier per order.
-- A single order can contain items from several suppliers (e.g. one from KL,
-- one from Sabah). Real marketplaces (Shopee/Lazada/Amazon) ship each seller's
-- items as an independent parcel with its own pickup, courier and tracking — so
-- the delivery table moves from one-row-per-order to one-row-per-(order,supplier).

-- 1) Add the supplier column (nullable while we backfill).
ALTER TABLE delivery
  ADD COLUMN supplierId VARCHAR(10) NULL AFTER orderId;

-- 2) Backfill existing rows with the order's first supplier. Pre-existing
--    multi-supplier orders are NOT retro-split here (they keep a single delivery
--    for their first supplier); re-seed dev data to get a clean per-supplier
--    split. New orders are split correctly by the dispatch logic.
UPDATE delivery d
  JOIN (
    SELECT oi.orderId, MIN(p.supplierId) AS supplierId
      FROM order_item oi
      JOIN product_variant pv ON pv.productVariantId = oi.productVariantId
      JOIN product p          ON p.productId = pv.productId
     GROUP BY oi.orderId
  ) x ON x.orderId = d.orderId
   SET d.supplierId = x.supplierId
 WHERE d.supplierId IS NULL;

-- 3) Swap the unique key (orderId) → (orderId, supplierId), add the index + FK,
--    and make the column NOT NULL now that it's populated.
ALTER TABLE delivery
  DROP INDEX uq_delivery_order,
  MODIFY supplierId VARCHAR(10) NOT NULL,
  ADD UNIQUE KEY uq_delivery_order_supplier (orderId, supplierId),
  ADD KEY idx_delivery_supplier (supplierId),
  ADD CONSTRAINT fk_delivery_supplier FOREIGN KEY (supplierId) REFERENCES supplier(supplierId)
      ON UPDATE CASCADE ON DELETE RESTRICT;
