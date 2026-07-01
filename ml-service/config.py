"""Configuration for the ShoeAR recommender service.

All values come from environment variables (with XAMPP-friendly defaults), so
no secrets live in the repo. The DB defaults match a stock local XAMPP MySQL.
"""
import os

DB = {
    'host':     os.environ.get('SHOEAR_DB_HOST', '127.0.0.1'),
    'port':     int(os.environ.get('SHOEAR_DB_PORT', '3306')),
    'user':     os.environ.get('SHOEAR_DB_USER', 'root'),
    'password': os.environ.get('SHOEAR_DB_PASS', ''),
    'database': os.environ.get('SHOEAR_DB_NAME', 'shoear'),
}

# Weighted-hybrid blend: final = ALPHA * CF(SVD) + (1 - ALPHA) * CBF(TF-IDF).
# 0.5 matches the validated WeightedHybridv1 prototype.
ALPHA = float(os.environ.get('SHOEAR_REC_ALPHA', '0.5'))

# scikit-surprise SVD hyper-parameters (mirror the prototype).
SVD_FACTORS = int(os.environ.get('SHOEAR_SVD_FACTORS', '100'))
SVD_EPOCHS  = int(os.environ.get('SHOEAR_SVD_EPOCHS', '40'))
SVD_LR      = float(os.environ.get('SHOEAR_SVD_LR', '0.005'))
SVD_REG     = float(os.environ.get('SHOEAR_SVD_REG', '0.05'))
RANDOM_SEED = 42

# Below this many ratings the CF (SVD) side is too sparse to be meaningful, so
# the service runs content-based only until more reviews accumulate.
MIN_RATINGS_FOR_CF = int(os.environ.get('SHOEAR_MIN_RATINGS', '10'))

TFIDF_MAX_FEATURES = 5000
PORT = int(os.environ.get('SHOEAR_ML_PORT', '5001'))
