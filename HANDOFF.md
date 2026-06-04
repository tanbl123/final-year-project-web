# ShoeAR — Project Handoff / Context Document

> **Purpose of this file:** Bring this to a new Claude Code session so it
> instantly understands the project, the decisions already made, and what to do
> next. In the new session, attach this file (and `database/schema.sql` +
> `database/NOTES.md`) and say: *"Read HANDOFF.md and continue from 'Next steps'."*

---

## 1. What the project is

**ShoeAR** — an AR-Based Sport Shoe Virtual Try-On platform with an ML product
recommender. Final-year university project.

A customer can:
- Browse sport shoes, see product details, images, reviews
- **Virtually try on** shoes using AR (a 3D model is overlaid on the foot via the camera)
- Get **ML-based recommendations**
- Add to cart/wishlist, checkout, pay, track delivery, leave reviews, request refunds

## 2. Architecture (three-tier client–server)

```
   4 client apps  ─────►  PHP REST API  ─────►  ONE shared MySQL database
   (presentation)         (logic layer)         (data layer)
```

- **Single MySQL database** is the shared source of truth for ALL apps.
- **PHP REST API** is the ONLY way apps touch the database (no app connects to MySQL directly).
- Runs locally in **XAMPP** (Apache + MySQL + PHP) + **phpMyAdmin** for DB admin.
- **Firebase Storage** holds product images and 3D model files (`.glb`/`.gltf`).
- Payments via **Stripe / PayPal**.

### The 4 apps
| App | Platform | Users | Purpose |
|-----|----------|-------|---------|
| Admin portal | Web | Admin | Approve users/products, assign deliveries, set commission, reports |
| Supplier portal | Web | Supplier | Upload products + 3D models, manage stock, view sales |
| Customer app | Mobile | Customer | Browse, AR try-on, recommendations, cart, checkout, track orders |
| Delivery app | Mobile | Delivery personnel | View assigned deliveries, update status, OTP + proof of delivery |

## 3. Roles & accounts
- Roles: **Admin, Supplier, Customer, DeliveryPersonnel**
- One base `user` row per account; a role-specific table extends it.
- Supplier & delivery personnel need **admin approval** (status `Pending` → `Active`).
- Customers are `Active` immediately on registration.

## 4. Database — DONE ✅

The schema is complete in **`database/schema.sql`** (22 tables) with rationale in
**`database/NOTES.md`**. Key facts:

- Derived faithfully from the report's **Data Dictionary (Section 4)** — 21 tables —
  plus **1 added** table (`product_variant`).
- String IDs with prefixes exactly as in the report (`USR0001`, `PRD0001`, ...).
- InnoDB + utf8mb4; ENUMs on every status field; FKs, unique keys, CHECK constraints.
- `created_at` / `updated_at` added for auditing and reports.

### Key design decisions already made (don't re-litigate these)
1. **Per-size stock (Option B).** Stock is tracked per size in a new
   `product_variant` table (productId + size + stockQuantity), NOT a single number
   on `product`. `cart_item` and `order_item` reference `productVariantId`.
   `wishlist_item` still references `productId`.
2. **Size is independent of AR.** AR try-on just overlays the 3D model; it does NOT
   measure or validate foot size. Size is purely a commerce/inventory concern.
3. **Atomic stock decrement** at payment success prevents overselling the "last pair"
   to two simultaneous buyers (UPDATE ... WHERE stockQuantity >= :qty inside a
   transaction). See NOTES.md Section 3.
4. **Price/size snapshots** in `order_item` (orderUnitPrice, orderSize) so history is
   preserved even if the product/variant later changes.

### Deliberately NOT in the schema yet (future increments)
- `notification` table (push notifications for order updates)
- AR try-on logs / ML interaction events (design during the ML increment)
- Stripe Connect payout records (when wiring supplier payouts)

## 5. Working method / environment notes
- Develop on a feature branch; commit from the user's own laptop (VS Code / GitHub
  Desktop) OR use a **write-enabled interactive Claude Code session** (started from
  claude.ai/code by selecting the repo) where the **"Create PR"** button works.
- Repo: `tanbl123/final-year-project-web`.
- The user is newer to git/web-dev workflows — explain steps clearly, plan before coding.

## 6. Next steps (resume here) ▶️
The agreed next planning task is the **REST API endpoint list** — the contract
between the database and the 4 apps. Suggested order after that:

1. **REST API endpoint design** (auth, products, cart, orders, payment, delivery,
   reviews, refunds, admin, supplier, ML recommend) — method, path, who calls it,
   request/response shape.
2. Decide the **first app to build** (suggest: Admin or Supplier web portal, since
   they populate the catalog the others depend on).
3. Build the **PHP REST API** skeleton + DB connection + auth (hashed passwords, JWT or session).
4. **AR module** (customer app) — load `.glb` model, overlay on foot.
5. **ML recommender** — design interaction logging + recommendation approach.

## 7. How to start the new session (for the user)
1. Go to **claude.ai/code**, start a new session, and **select `final-year-project-web`**
   (this gives the session write access + the "Create PR" button).
2. Attach **HANDOFF.md**, **database/schema.sql**, **database/NOTES.md**.
3. First message: *"Read HANDOFF.md. We finished the database; let's design the REST
   API endpoint list next."*
