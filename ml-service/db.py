"""Read-only data access for the recommender — pulls ShoeAR's live MySQL data
(products, published reviews, sales) into plain Python dicts/lists.

The recommender only ever READS; it never writes to the database.
"""
import pymysql
from pymysql.cursors import DictCursor

import config


def _connect():
    return pymysql.connect(
        host=config.DB['host'], port=config.DB['port'],
        user=config.DB['user'], password=config.DB['password'],
        database=config.DB['database'], cursorclass=DictCursor, charset='utf8mb4',
    )


def _query(sql, params=None):
    conn = _connect()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.fetchall()
    finally:
        conn.close()


def load_products():
    """Approved products with the text attributes used for content-based TF-IDF."""
    return _query(
        """
        SELECT p.productId          AS productId,
               p.productName         AS name,
               p.productBrand        AS brand,
               c.categoryName        AS category,
               p.productDescription  AS description,
               p.productPrice        AS price
          FROM product p
          JOIN category c ON c.categoryId = p.categoryId
         WHERE p.productStatus = 'Approved'
         ORDER BY p.productId
        """
    )


def load_reviews():
    """Published ratings — the (customer, product, rating) matrix for SVD/CF."""
    return _query(
        """
        SELECT customerId AS customerId,
               productId   AS productId,
               ratingScore AS rating
          FROM review
         WHERE reviewStatus = 'Published'
        """
    )


def load_popularity():
    """Units sold per approved product (paid+ orders) — the trending signal."""
    return _query(
        """
        SELECT p.productId AS productId, SUM(oi.orderQuantity) AS sold
          FROM order_item oi
          JOIN product_variant pv ON pv.productVariantId = oi.productVariantId
          JOIN product p          ON p.productId = pv.productId
          JOIN `order` o          ON o.orderId = oi.orderId
         WHERE o.orderStatus IN ('Paid','Processing','Shipped','OutForDelivery','Delivered','Completed')
           AND p.productStatus = 'Approved'
         GROUP BY p.productId
        """
    )
