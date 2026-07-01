# ShoeAR Recommender — Flask ML Service

A weighted-hybrid recommender (the same algorithm validated in the
`WeightedHybridv1` prototype) served as a small Python Flask API that reads the
platform's live MySQL data:

- **Content-based (CBF):** TF-IDF over product text (name + brand + category +
  description) + normalized price, item-item cosine similarity.
- **Collaborative (CF):** scikit-surprise **SVD** matrix factorization over the
  `review` ratings.
- **Weighted hybrid:** `final = 0.5·CF + 0.5·CBF` (α configurable).

The PHP backend proxies to this service and turns the returned product IDs into
full product cards, so this stays a thin ML layer. If the service is offline,
the PHP side falls back to a simple SQL query, so the app never breaks.

## Run locally (alongside XAMPP)

```bash
cd ml-service
python -m venv venv
venv\Scripts\activate            # Windows   (macOS/Linux: source venv/bin/activate)
pip install -r requirements.txt
python app.py                     # serves on http://127.0.0.1:5001
```

Check it: open <http://127.0.0.1:5001/health> — you should see product/review counts.

## Configuration (environment variables, all optional)

Defaults match a stock local XAMPP MySQL (`root`, no password, db `shoear`).

| Variable | Default | Meaning |
|---|---|---|
| `SHOEAR_DB_HOST` / `SHOEAR_DB_PORT` | `127.0.0.1` / `3306` | MySQL host/port |
| `SHOEAR_DB_USER` / `SHOEAR_DB_PASS` | `root` / *(empty)* | MySQL credentials |
| `SHOEAR_DB_NAME` | `shoear` | database name |
| `SHOEAR_REC_ALPHA` | `0.5` | CF vs CBF blend weight |
| `SHOEAR_ML_PORT` | `5001` | port this service listens on |

Point the PHP backend at it by adding to `backend/config.local.php`:

```php
'ml_service_url' => 'http://127.0.0.1:5001',
```

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | status + product/review counts + whether CF is active |
| GET | `/recommend/similar?productId=PRD0001&k=10` | content-based "you may also like" |
| GET | `/recommend/for-you?customerId=CUS0001&k=10` | personalized hybrid (trending fallback) |
| GET | `/recommend/trending?k=10` | best-sellers |
| POST | `/reload` | retrain from the latest DB data (call after seeding/new reviews) |

## Notes

- **Cold start:** with few reviews the CF/SVD side is skipped automatically and
  recommendations use the content-based + trending signals. Seed some reviews
  (and call `POST /reload`) to activate CF for a demo.
- **scikit-surprise install:** needs numpy<2 and a C toolchain. On Windows, if
  `pip install scikit-surprise` fails to build, install a prebuilt wheel
  (e.g. `pip install scikit-surprise --only-binary :all:`) or use conda. If it
  still isn't available the service runs content-based only (it logs this).
