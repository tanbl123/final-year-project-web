import { useState, useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import ProductCard from '../components/ProductCard';
import ProductFilterBar from '../components/ProductFilterBar';
import ConfirmDialog from '../../../components/ConfirmDialog';
import { fetchProducts, deleteProduct } from '../productService';

const EMPTY_FILTERS = { name: '', brand: '', maxPrice: '', categoryId: '', status: '' };

function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  const [filters, setFilters] = useState(EMPTY_FILTERS);

  const [dialog, setDialog] = useState({
    isOpen: false, title: '', message: '',
    confirmText: 'Confirm', confirmColor: 'primary', onConfirm: () => {},
  });

  function closeDialog() {
    setDialog((d) => ({ ...d, isOpen: false }));
  }

  // load this supplier's products from the API on first render
  useEffect(() => {
    fetchProducts()
      .then((data) => setProducts(data))
      .catch((err) => setError(err.message))
      .finally(() => setIsLoading(false));
  }, []);

  function askDelete(id) {
    setDialog({
      isOpen: true,
      title: 'Delete product',
      message: 'Are you sure you want to delete this product?',
      confirmText: 'Delete',
      confirmColor: 'danger',
      onConfirm: async () => {
        try {
          await deleteProduct(id);
          setProducts((prev) => prev.filter((shoe) => shoe.id !== id));
        } catch (err) {
          setError(err.message);
        }
        closeDialog();
      },
    });
  }

  // client-side filtering driven by the filter bar
  const visible = useMemo(() => {
    const name = filters.name.trim().toLowerCase();
    const brand = filters.brand.trim().toLowerCase();
    const maxPrice = filters.maxPrice === '' ? null : Number(filters.maxPrice);
    return products.filter((p) => {
      if (name && !p.name.toLowerCase().includes(name)) return false;
      if (brand && !p.brand.toLowerCase().includes(brand)) return false;
      if (filters.categoryId && p.categoryId !== filters.categoryId) return false;
      if (filters.status && p.status !== filters.status) return false;
      if (maxPrice !== null && !Number.isNaN(maxPrice) && p.price > maxPrice) return false;
      return true;
    });
  }, [products, filters]);

  return (
    <div className="container py-4">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h1 className="mb-0">👟 Supplier Products</h1>
        <Link to="/products/new" className="btn btn-primary">+ Add product</Link>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      <ProductFilterBar filters={filters} onChange={setFilters} />

      {isLoading ? (
        <div className="text-center my-5">
          <div className="spinner-border text-primary" role="status"></div>
          <p className="mt-2">Loading products...</p>
        </div>
      ) : (
        <>
          <p className="text-muted">
            Showing {visible.length} of {products.length} product{products.length === 1 ? '' : 's'}
          </p>
          {visible.length === 0 ? (
            <div className="card card-body text-center text-muted">
              {products.length === 0
                ? 'No products yet. Click “+ Add product” to create your first one.'
                : 'No products match these filters.'}
            </div>
          ) : (
            <div className="row g-3">
              {visible.map((shoe) => (
                <div className="col-12 col-sm-6 col-md-4 col-lg-3" key={shoe.id}>
                  <ProductCard
                    id={shoe.id}
                    name={shoe.name}
                    brand={shoe.brand}
                    price={shoe.price}
                    status={shoe.status}
                    imageUrl={shoe.imageUrl}
                    totalStock={shoe.totalStock}
                    onDelete={askDelete}
                  />
                </div>
              ))}
            </div>
          )}
        </>
      )}

      <ConfirmDialog
        isOpen={dialog.isOpen}
        title={dialog.title}
        message={dialog.message}
        confirmText={dialog.confirmText}
        confirmColor={dialog.confirmColor}
        onConfirm={dialog.onConfirm}
        onCancel={closeDialog}
      />
    </div>
  );
}

export default ProductsPage;
