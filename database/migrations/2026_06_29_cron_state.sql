-- App-level cron throttle.
--
-- The time-based sweeps (payment reminders, abandoned carts, review reminders,
-- auto-cancel expired orders, courier monthly payout) normally need an OS cron
-- to fire them on a timer. Instead, the app runs them ITSELF: after handling a
-- request it checks this single-row table and, if the last run is older than the
-- configured interval, claims the slot (atomic UPDATE) and runs the sweeps once.
--
-- One row (id = 1). lastSweepAt is the last time the sweeps actually ran.
--
-- Apply to an existing database:
--   phpMyAdmin → shoear database → SQL → paste → Go

CREATE TABLE IF NOT EXISTS cron_state (
  id          TINYINT UNSIGNED NOT NULL PRIMARY KEY,
  lastSweepAt DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO cron_state (id, lastSweepAt) VALUES (1, NULL);
