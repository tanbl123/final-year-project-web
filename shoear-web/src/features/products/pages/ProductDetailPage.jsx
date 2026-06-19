import { useState, useEffect } from 'react';
import { useParams, useLocation, useNavigate, Link } from 'react-router-dom';
import { fetchProductById } from '../productService';
import BackButton from '../../../components/BackButton';
import Toast from '../../../components/Toast';

const STATUS_COLORS = { Approved: 'success', Pending: 'warning', Rejected: 'danger' };

function ProductDetailPage() {
  const { id } = useParams();          // 👈 read the :id from the URL
  const [product, setProduct] = useState(null);
  const [activeImage, setActiveImage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');

  // an edit redirect lands here with a toast message to show
  const location = useLocation();
  const navigate = useNavigate();
  useEffect(() => {
    if (location.state?.toast) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setToast(location.state.toast);
      navigate(location.pathname, { replace: true });   // clear it so it won't reappear
    }
  }, [location, navigate]);

  useEffect(() => {
    setIsLoading(true);
    fetchProductById(id)
      .then((data) => {
        setProduct(data);
        setActiveImage(data.images?.[0] || '');
      })
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
        <BackButton to="/products" />
      </div>
    );
  }

  const statusColor = STATUS_COLORS[product.status] || 'secondary';

  return (
    <div className="container py-4">
      <BackButton to="/products" />

      <div className="row g-4 mt-1">
        {/* left: images */}
        <div className="col-md-6">
          <div className="ratio ratio-1x1 bg-light rounded border overflow-hidden">
            {activeImage ? (
              <img src={activeImage} alt={product.name} style={{ objectFit: 'cover' }} className="w-100 h-100" />
            ) : (
              <div className="d-flex align-items-center justify-content-center text-muted display-1">👟</div>
            )}
          </div>
          {product.images?.length > 1 && (
            <div className="d-flex flex-wrap gap-2 mt-2">
              {product.images.map((url) => (
                <img key={url} src={url} alt="" onClick={() => setActiveImage(url)}
                  className={'rounded border ' + (url === activeImage ? 'border-primary border-2' : '')}
                  style={{ width: 70, height: 70, objectFit: 'cover', cursor: 'pointer' }} />
              ))}
            </div>
          )}
        </div>

        {/* right: details */}
        <div className="col-md-6">
          <div className="d-flex justify-content-between align-items-start">
            <h2 className="mb-0">{product.name}</h2>
            <span className={`badge text-bg-${statusColor}`}>{product.status}</span>
          </div>
          <Link to={`/products/${id}/edit`} className="btn btn-outline-primary btn-sm mt-2">
            ✎ Edit product
          </Link>
          <h6 className="text-muted mt-1">{product.brand}</h6>
          <p className="fs-2 fw-bold text-primary mb-2">RM {Number(product.price).toFixed(2)}</p>
          <p className="mb-3">
            <span className="badge text-bg-light me-2">{product.categoryName}</span>
            {product.virtualTryOnEnable && <span className="badge text-bg-info">AR try-on enabled</span>}
          </p>

          {product.description && <p>{product.description}</p>}

          <h5 className="mt-4">Sizes &amp; stock</h5>
          {product.variants?.length > 0 ? (
            <table className="table table-sm w-auto">
              <thead><tr><th>Size</th><th className="text-end">Stock</th></tr></thead>
              <tbody>
                {product.variants.map((v) => (
                  <tr key={v.size}>
                    <td>{v.size}</td>
                    <td className="text-end">{v.stock}</td>
                  </tr>
                ))}
                <tr className="fw-bold border-top">
                  <td>Total</td>
                  <td className="text-end">{product.totalStock}</td>
                </tr>
              </tbody>
            </table>
          ) : (
            <p className="text-muted">No sizes added.</p>
          )}

          <p className="text-muted small mb-0">Product ID: {product.id}</p>
        </div>
      </div>

      {/* 3D model preview */}
      {product.modelUrl && (
        <div className="mt-5">
          <h4>3D model</h4>
          <model-viewer
            src={product.modelUrl}
            camera-controls
            auto-rotate
            ar
            shadow-intensity="1"
            style={{ width: '100%', height: '420px', background: '#f8f9fa', borderRadius: '0.5rem' }}
          ></model-viewer>
        </div>
      )}

      <Toast message={toast} onClose={() => setToast('')} />
    </div>
  );
}

export default ProductDetailPage;
