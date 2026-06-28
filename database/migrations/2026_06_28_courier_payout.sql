-- Per-delivery courier earnings, paid out via Stripe Connect.
-- Run against the project database, e.g.:  USE shoear;

-- 1. Couriers get a Stripe Connect account for payouts (mirrors supplier).
ALTER TABLE delivery_personnel
  ADD COLUMN stripeAccountId VARCHAR(60) NULL              AFTER coverageZones,
  ADD COLUMN payoutsEnabled  TINYINT(1)  NOT NULL DEFAULT 0 AFTER stripeAccountId;

-- 2. Each delivery snapshots the fee the courier earns + which payout cleared it.
ALTER TABLE delivery
  ADD COLUMN courierFee      DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER proofOfDelivery,
  ADD COLUMN courierPayoutId VARCHAR(10)   NULL               AFTER courierFee,
  ADD KEY idx_delivery_courier_payout (courierPayoutId);

-- 3. One row per payout the admin makes to a courier.
CREATE TABLE courier_payout (
    payoutId            VARCHAR(10)   NOT NULL,
    deliveryPersonnelId VARCHAR(10)   NOT NULL,
    stripeTransferId    VARCHAR(60)   NULL,
    amount              DECIMAL(10,2) NOT NULL,
    deliveryCount       INT           NOT NULL DEFAULT 0,
    currency            CHAR(3)       NOT NULL DEFAULT 'myr',
    payoutStatus        ENUM('Pending','Paid','Failed') NOT NULL DEFAULT 'Pending',
    created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (payoutId),
    KEY idx_courier_payout_dp (deliveryPersonnelId),
    CONSTRAINT fk_courier_payout_dp FOREIGN KEY (deliveryPersonnelId) REFERENCES delivery_personnel(deliveryPersonnelId)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_courier_payout_amount CHECK (amount >= 0)
) ENGINE=InnoDB;
