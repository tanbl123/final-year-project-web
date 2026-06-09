import { useState, useEffect } from 'react';
import ProductCard from './features/products/components/ProductCard';
import ConfirmDialog from './features/products/components/ConfirmDialog';
import AddProductForm from './features/products/components/AddProductForm';
import { fetchProducts } from './features/products/productService';

function App() {
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

  // called by AddProductForm when a valid product is ready
  function addProduct(newProductData) {
    const newShoe = {
      id: 'PRD' + Date.now(),
      ...newProductData,          // spreads name, brand, price into the object
    };
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
      <h1 className="mb-4">👟 ShoeAR Supplier Portal</h1>

      {/* the form is now one clean line */}
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

export default App;