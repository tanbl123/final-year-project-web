import { useState, useEffect } from 'react';
import ProductCard from '../components/ProductCard';
import AddProductForm from '../components/AddProductForm';
import ConfirmDialog from '../../../components/ConfirmDialog';
import { fetchProducts } from '../productService';

function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  const [dialog, setDialog] = useState({
    isOpen: false, title: '', message: '',
    confirmText: 'Confirm', confirmColor: 'primary', onConfirm: () => {},
  });

  function closeDialog() {
    setDialog((d) => ({ ...d, isOpen: false }));
  }

  useEffect(() => {
    fetchProducts().then((data) => {
      setProducts(data);
      setIsLoading(false);
    });
  }, []);

  function addProduct(newProductData) {
    const newShoe = { id: 'PRD' + Date.now(), ...newProductData };
    setProducts((prev) => [...prev, newShoe]);
  }

  function askDelete(id) {
    setDialog({
      isOpen: true,
      title: 'Delete product',
      message: 'Are you sure you want to delete this product?',
      confirmText: 'Delete',
      confirmColor: 'danger',
      onConfirm: () => {
        setProducts((prev) => prev.filter((shoe) => shoe.id !== id));
        closeDialog();
      },
    });
  }

  return (
    <div className="container py-4">
      <h1 className="mb-4">👟 Supplier Products</h1>

      <AddProductForm onAdd={addProduct} />

      {isLoading ? (
        <div className="text-center my-5">
          <div className="spinner-border text-primary" role="status"></div>
          <p className="mt-2">Loading products...</p>
        </div>
      ) : (
        <>
          <p className="text-muted">My products: ({products.length} total)</p>
          <div className="row g-3">
            {products.map((shoe) => (
              <div className="col-12 col-sm-6 col-md-4 col-lg-3" key={shoe.id}>
                <ProductCard
                  id={shoe.id}
                  name={shoe.name}
                  brand={shoe.brand}
                  price={shoe.price}
                  onDelete={askDelete}
                />
              </div>
            ))}
          </div>
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