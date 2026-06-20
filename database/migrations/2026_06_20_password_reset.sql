-- Password-reset codes ("forgot password" flow).
--
-- A user who forgot their password requests a code (POST /auth/forgot-password),
-- which is emailed to their REGISTERED address; they then enter the code plus a
-- new password (POST /auth/reset-password). Mirrors the registration
-- email_verification table but kept separate so a reset code and a sign-up code
-- for the same address can never collide.
--
-- One pending reset per email (keyed by email). Only a HASH of the code is
-- stored, with an expiry, a resend timestamp (cooldown) and an attempt counter.
--
-- Apply to an existing database that was built before this table existed:
--   phpMyAdmin → shoear database → SQL → paste → Go

CREATE TABLE IF NOT EXISTS password_reset (
    email        VARCHAR(120) NOT NULL,                 -- the account's email
    codeHash     VARCHAR(255) NOT NULL,                 -- bcrypt hash of the 6-digit code
    attempts     INT          NOT NULL DEFAULT 0,       -- failed verify attempts (cap at 5)
    expires_at   DATETIME     NOT NULL,                 -- code is invalid after this
    last_sent_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP, -- for the resend cooldown
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (email)
) ENGINE=InnoDB;
