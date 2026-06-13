import { useNavigate, Link } from 'react-router-dom';
import ProductForm from '../components/ProductForm';
import { createProduct } from '../productService';

// Dedicated page for creating a product (instead of an inline panel on the
// products list). On success we return to the list, which refetches on mount
// and shows the new product.
function AddProductPage() {
  const navigate = useNavigate();

  // Throw on failure so ProductForm shows the error inline and stays open.
  async function addProduct(newProductData) {
    await createProduct(newProductData);
  }

  return (
    <div className="container py-4 text-start">
      <Link to="/products" className="btn btn-outline-secondary mb-3" title="Back to products" aria-label="Back to products">
        ← Back
      </Link>
      <h1 className="mb-4">Add a product</h1>
      <ProductForm onAdd={addProduct} onCancel={() => navigate('/products')} />
    </div>
  );
}

export default AddProductPage;
