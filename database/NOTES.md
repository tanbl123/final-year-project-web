# Database Design Notes — ShoeAR

This document explains the design decisions behind `schema.sql` so they can
be defended in the report and during evaluation.

## 1. Faithful to the Data Dictionary

All 21 tables come directly from the report's Data Dictionary (Section 4):

`user`, `admin`, `supplier`, `customer`, `delivery_personnel`, `category`,
`product`, `product_image`, `product_model`, `cart`, `cart_item`, `wishlist`,
`wishlist_item`, `order`, `order_item`, `payment`, `receipt`, `delivery`,
`review`, `refund`, `commission`.

The string-ID convention (`USR0001`, `PRD0001`, ...) is kept exactly as written.

## 2. Small additions (not in the dictionary, but standard practice)

These do **not** change the design — they make the written requirements work:

| Addition | Why |
|----------|-----|
| `ENUM` on every status field | Report lists specific statuses; ENUM makes invalid values impossible. |
| `created_at` / `updated_at` | Needed for the Sales/Commission **reports** and auditing. |
| `payment.paymentMethod` | Report's checkout says customer "selects a payment method" (Stripe/PayPal). |
| Unique keys (email, username, one cart per customer, one review per product) | Enforce the rules the report describes in prose. |
| `CHECK` constraints (price ≥ 0, rating 1–5) | Data integrity (a Reliability non-functional requirement). |
| Foreign keys + `InnoDB` | Required for relationships AND for the transaction/locking below. |

## 3. The "last pair / two buyers" problem (atomic stock decrement)

This satisfies the report's **Reliability** ("transaction records stored
accurately") and **Performance** ("multiple users simultaneously") requirements.

Stock lives in `product_variant.stockQuantity` (per size). At **payment
success**, the API runs this inside a transaction:

```sql
START TRANSACTION;

UPDATE product_variant
   SET stockQuantity = stockQuantity - :qty
 WHERE productVariantId = :id
   AND stockQuantity >= :qty;     -- the safety condition

-- If affected rows = 0  -> not enough stock -> ROLLBACK + tell the customer
-- If affected rows = 1  -> stock reserved   -> create order/payment -> COMMIT
COMMIT;
```

Because the database serialises these updates, two customers buying the **last
pair** at the same instant cannot both succeed: the first wins, the second's
`WHERE stockQuantity >= :qty` matches zero rows and is rejected. This is the
same mechanism real e-commerce/banking/ticketing systems use. No overselling,
guaranteed at the data layer (not the UI).

## 4. Shoe sizes — DECIDED: stock per size (Option B)

The functional requirements mention "available sizes", but the original Data
Dictionary modelled stock as a single number per product. We chose **Option B**:
track stock **per size** via a new `product_variant` table.

**Important:** size is a *commerce/inventory* concern only — it is **completely
independent of AR**. The AR try-on overlays the same 3D model regardless of size
and does NOT measure or validate foot size, so nothing in AR depends on this.

What changed vs. the raw Data Dictionary (a small, justified structural change):

| Table | Change |
|-------|--------|
| `product` | `stockQuantity` **removed** — stock now lives on the variant. |
| `product_variant` (new) | `productId` + `size` + its own `stockQuantity`. One row per (product, size). |
| `cart_item` | References `productVariantId` (the chosen size) instead of `productId`. |
| `order_item` | References `productVariantId` + snapshots `orderSize` for history. |
| `wishlist_item` | Still references `productId` — you wishlist a *product*, not a size. |

The atomic stock decrement (Section 3) now runs on the **variant** row, so "UK8
sold out, UK9 still available" works correctly, and two buyers can't take the
last UK9 pair.

## 5. Not yet included (later increments)

- **Notifications** (push notifications for order updates) — add a
  `notification` table when we build that feature.
- **AR try-on logs / ML interaction events** — the recommender may need a table
  of user–product interactions; we'll design it in the ML increment.
- **Stripe Connect payout records** — add when wiring supplier payouts.
