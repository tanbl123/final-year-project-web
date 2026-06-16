-- Supplier business-detail change requests (post-approval re-verification).
-- Verified KYB fields (company name, SSM, SST, business document) can't be
-- silently edited after approval. Instead a supplier submits a change request;
-- the account stays Active and keeps selling while an admin reviews it. On
-- approval the proposed values are copied onto the live supplier row; on
-- rejection the live row is untouched and the supplier sees the reason.
--
-- Apply to an existing database:
--   phpMyAdmin → shoear database → SQL → paste → Go

CREATE TABLE IF NOT EXISTS supplier_change_request (
    requestId          VARCHAR(10)  NOT NULL,                 -- SCR0001
    supplierId         VARCHAR(10)  NOT NULL,
    companyName        VARCHAR(150) NOT NULL,                 -- proposed values
    businessRegNo      VARCHAR(50)  NOT NULL,
    taxNumber          VARCHAR(50)  NULL,
    businessLicenseUrl VARCHAR(255) NOT NULL,
    requestStatus      ENUM('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
    reviewNote         VARCHAR(255) NULL,                     -- admin reason on reject
    reviewedBy         VARCHAR(10)  NULL,                     -- admin userId who reviewed
    created_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reviewed_at        DATETIME     NULL,
    PRIMARY KEY (requestId),
    KEY idx_scr_supplier (supplierId),
    KEY idx_scr_status (requestStatus),
    CONSTRAINT fk_scr_supplier FOREIGN KEY (supplierId) REFERENCES supplier(supplierId)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;
