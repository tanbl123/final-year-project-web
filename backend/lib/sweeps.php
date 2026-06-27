<?php
// ─────────────────────────────────────────────────────────────────────
// Time-based notification sweeps.
//
// These are the notifications that can't be fired by a single user action —
// they depend on TIME PASSING (an unpaid order nearing its deadline, a cart
// left untouched, an order delivered a while ago). Real platforms run these on
// a scheduler (cron). Here they live behind one entry point, runNotificationSweeps(),
// which the admin can trigger on demand (POST /admin/run-sweeps) for a live demo
// and a real cron can call on a timer in production.
//
// Each sweep is idempotent — it uses the notification table (or a per-cart
// marker) to avoid re-notifying the same thing twice — so running it repeatedly
// is safe. Everything is best-effort and never throws.
// ─────────────────────────────────────────────────────────────────────

// How long before the auto-cancel deadline we nudge the buyer to pay.
const PAYMENT_REMINDER_LEAD_MINUTES = 15;
// How long a cart sits untouched (with items, no checkout) before it's "abandoned".
const CART_ABANDON_MINUTES = 60;

// Remind buyers whose unpaid orders are close to the auto-cancel deadline.
// One reminder per order (deduped via the existing 'payment' notification).
function sweepPaymentReminders(PDO $pdo): int {
  $window = defined('ORDER_PAYMENT_WINDOW_MINUTES') ? ORDER_PAYMENT_WINDOW_MINUTES : 60;
  $leadStart = max(1, $window - PAYMENT_REMINDER_LEAD_MINUTES);  // age at which we start reminding
  try {
    $stmt = $pdo->prepare(
      "SELECT o.orderId, TIMESTAMPDIFF(MINUTE, o.orderDate, NOW()) AS ageMin
         FROM `order` o
        WHERE o.orderStatus = 'Placed'
          AND o.orderDate <= (NOW() - INTERVAL :lead MINUTE)
          AND o.orderDate >  (NOW() - INTERVAL :win MINUTE)
          AND NOT EXISTS (SELECT 1 FROM payment p
                           WHERE p.orderId = o.orderId AND p.paymentStatus = 'Successful')
          AND NOT EXISTS (SELECT 1 FROM notification n
                           WHERE n.orderId = o.orderId AND n.type = 'payment')"
    );
    $stmt->execute(['lead' => $leadStart, 'win' => $window]);
    $rows = $stmt->fetchAll();
  } catch (Throwable $e) {
    return 0;
  }
  $sent = 0;
  foreach ($rows as $r) {
    $left = max(1, $window - (int) $r['ageMin']);
    notifyPaymentReminder($pdo, $r['orderId'], $left);
    $sent++;
  }
  return $sent;
}

// Remind customers who left items in their cart and never checked out.
// Re-arms automatically: bumping cartUpdatedAt (on any cart change) makes the
// cart eligible again, since we only skip carts reminded SINCE their last change.
function sweepAbandonedCarts(PDO $pdo): int {
  try {
    $stmt = $pdo->prepare(
      "SELECT c.cartId, cu.userId
         FROM cart c
         JOIN customer cu ON cu.customerId = c.customerId
        WHERE EXISTS (SELECT 1 FROM cart_item ci WHERE ci.cartId = c.cartId)
          AND c.cartUpdatedAt <= (NOW() - INTERVAL :stale MINUTE)
          AND (c.cartReminderSentAt IS NULL OR c.cartReminderSentAt < c.cartUpdatedAt)
          AND cu.userId IS NOT NULL"
    );
    $stmt->execute(['stale' => CART_ABANDON_MINUTES]);
    $rows = $stmt->fetchAll();
  } catch (Throwable $e) {
    return 0;
  }
  $mark = $pdo->prepare('UPDATE cart SET cartReminderSentAt = NOW() WHERE cartId = :id');
  $sent = 0;
  foreach ($rows as $r) {
    createNotification($pdo, (string) $r['userId'], 'cart', 'You left items in your cart',
      'Your cart is waiting — complete your purchase before these sell out.');
    try { $mark->execute(['id' => $r['cartId']]); } catch (Throwable $e) {/* ignore */}
    $sent++;
  }
  return $sent;
}

// Nudge buyers to review delivered orders that still have un-reviewed items.
// One reminder per order (deduped via the existing 'review' notification).
function sweepReviewReminders(PDO $pdo): int {
  try {
    $stmt = $pdo->query(
      "SELECT o.orderId, o.customerId
         FROM `order` o
        WHERE o.orderStatus = 'Delivered'
          AND NOT EXISTS (SELECT 1 FROM notification n
                           WHERE n.orderId = o.orderId AND n.type = 'review')"
    );
    $rows = $stmt->fetchAll();
  } catch (Throwable $e) {
    return 0;
  }
  $unreviewed = $pdo->prepare(
    "SELECT COUNT(*) FROM (
        SELECT DISTINCT p.productId
          FROM order_item oi
          JOIN product_variant pv ON pv.productVariantId = oi.productVariantId
          JOIN product p          ON p.productId = pv.productId
         WHERE oi.orderId = :oid
     ) prods
     LEFT JOIN review r ON r.productId = prods.productId AND r.customerId = :cid
     WHERE r.reviewId IS NULL"
  );
  $sent = 0;
  foreach ($rows as $r) {
    try {
      $unreviewed->execute(['oid' => $r['orderId'], 'cid' => $r['customerId']]);
      if ((int) $unreviewed->fetchColumn() > 0) {
        notifyReviewReminderForOrder($pdo, $r['orderId']);
        $sent++;
      }
    } catch (Throwable $e) {/* skip this order */}
  }
  return $sent;
}

// Run every time-based sweep. Returns per-sweep counts (handy for the demo).
// Also tidies up expired unpaid orders (which notifies on auto-cancel).
function runNotificationSweeps(PDO $pdo): array {
  $cancelled = 0;
  if (function_exists('cancelExpiredUnpaidOrders')) {
    $cancelled = cancelExpiredUnpaidOrders($pdo);
  }
  return [
    'paymentReminders' => sweepPaymentReminders($pdo),
    'abandonedCarts'   => sweepAbandonedCarts($pdo),
    'reviewReminders'  => sweepReviewReminders($pdo),
    'autoCancelled'    => $cancelled,
  ];
}
