import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { fetchProductById } from '../productService';

function ProductDetailPage() {
  const { id } = useParams();          // 👈 read the :id from the URL
  const [product, setProduct] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    setIsLoading(true);
    fetchProductById(id)
      .then((data) => setProduct(data))
      .catch((err) => setError(err.message))
      .finally(() => setIsLoading(false));
  }, [id]);                            // 👈 re-run if the id changes

  if (isLoading) {
    return <div className="container py-4"><p>Loading...</p></div>;
  }
  if (error) {
    return (
      <div className="container py-4">
        <div className="alert alert-danger">{error}</div>
        <Link to="/products">← Back to products</Link>
      </div>
    );
  }

  return (
    <div className="container py-4">
      <Link to="/products" className="btn btn-link px-0">← Back to products</Link>
      <div className="card shadow-sm mt-2" style={{ maxWidth: '500px' }}>
        <div className="card-body">
          <h2 className="card-title">{product.name}</h2>
          <h6 className="text-muted">{product.brand}</h6>
          <p className="fs-3 fw-bold text-primary">RM {product.price}</p>
          <p className="text-muted mb-0">Product ID: {product.id}</p>
        </div>
      </div>
    </div>
  );
}

export default ProductDetailPage;