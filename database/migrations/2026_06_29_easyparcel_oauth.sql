-- EasyParcel OAuth token store (Open API).
--
-- The EasyParcel "Open API" uses OAuth2: the admin connects ShoeAR once
-- (consent screen → authorization code → token exchange), and the backend then
-- holds a long-lived refresh token (~1 year) which it swaps for short-lived
-- access tokens (~10 hours) on demand. We keep ONE row (id = 1) — the whole
-- platform books shipments through a single EasyParcel merchant account.
--
-- Tokens are secrets, but they live in the app database (not git) and are
-- refreshed automatically; disconnecting clears them. pendingState holds the
-- one-time CSRF token while the admin is on EasyParcel's consent screen.
--
-- Apply to an existing database:
--   phpMyAdmin → shoear database → SQL → paste → Go

CREATE TABLE IF NOT EXISTS easyparcel_oauth (
  id               TINYINT UNSIGNED NOT NULL PRIMARY KEY,
  accessToken      TEXT         NULL,
  accessExpiresAt  DATETIME     NULL,
  refreshToken     TEXT         NULL,
  refreshExpiresAt DATETIME     NULL,
  accountId        VARCHAR(64)  NULL,
  pendingState     VARCHAR(64)  NULL,
  pendingStateAt   DATETIME     NULL,
  connectedAt      DATETIME     NULL,
  updatedAt        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- The single row the app reads/writes.
INSERT IGNORE INTO easyparcel_oauth (id) VALUES (1);
