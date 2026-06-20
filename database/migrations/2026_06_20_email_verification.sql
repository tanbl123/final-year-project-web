-- Email-verification codes for supplier registration.
--
-- Suppliers must prove they own the email they register with: the form first
-- requests a 6-digit code (POST /auth/register/send-code), which is emailed to
-- them; the account is only created once that code is entered back on
-- /auth/register. One pending code per email (keyed by email), so requesting a
-- fresh code overwrites the previous one.
--
-- We store only a HASH of the code (never the code itself), an expiry, a
-- resend timestamp (for the cooldown) and a verification-attempt counter (to
-- stop brute-forcing the 6 digits).
--
-- Apply to an existing database that was built before this table existed:
--   phpMyAdmin → shoear database → SQL → paste → Go

CREATE TABLE IF NOT EXISTS email_verification (
    email        VARCHAR(120) NOT NULL,                 -- the email being verified
    codeHash     VARCHAR(255) NOT NULL,                 -- bcrypt hash of the 6-digit code
    attempts     INT          NOT NULL DEFAULT 0,       -- failed verify attempts (cap at 5)
    expires_at   DATETIME     NOT NULL,                 -- code is invalid after this
    last_sent_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP, -- for the resend cooldown
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (email)
) ENGINE=InnoDB;
