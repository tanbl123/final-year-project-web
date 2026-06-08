import { useState, useEffect } from 'react';
import ProductCard from './ProductCard';

function fakeFetchProducts() {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve([
        { id: 'PRD0001', name: 'Air Zoom Pegasus', brand: 'Nike',   price: 399 },
        { id: 'PRD0002', name: 'UltraBoost 22',    brand: 'Adidas', price: 549 },
        { id: 'PRD0003', name: 'Gel-Kayano',       brand: 'Asics',  price: 459 },
      ]);
    }, 1000);
  });
}

function App() {
  const [products, setProducts] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  // ① one state for each input box in the form
  const [name, setName] = useState('');
  const [brand, setBrand] = useState('');
  const [price, setPrice] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    fakeFetchProducts().then((data) => {
      setProducts(data);
      setIsLoading(false);
    });
  }, []);

  // ② runs when the form is submitted
  function handleSubmit(event) {
    event.preventDefault();

    const cleanName = name.trim();
    const cleanBrand = brand.trim();
    const priceNumber = Number(price);

    // --- NAME & BRAND: only "not empty" + "not too long" (allow all characters) ---
    if (cleanName === '' || cleanBrand === '') {
      setError('Name and brand cannot be empty.');
      return;
    }
    if (cleanName.length > 100) {
      setError('Shoe name is too long (max 100 characters).');
      return;
    }
    if (cleanBrand.length > 100) {
      setError('Brand is too long (max 100 characters).');
      return;
    }

    // --- PRICE: must be a valid, positive, sensible number ---
    if (Number.isNaN(priceNumber) || priceNumber <= 0) {
      setError('Price must be a number greater than 0.');
      return;
    }
    if (priceNumber > 100000) {
      setError('Price seems too high. Please check.');
      return;
    }

    // --- All checks passed: build and add the product ---
    const newShoe = {
      id: 'PRD' + Date.now(),
      name: cleanName,
      brand: cleanBrand,
      price: Math.round(priceNumber * 100) / 100,   // round to 2 decimals
    };

    setProducts([...products, newShoe]);

    // Clear the form + any old error
    setName('');
    setBrand('');
    setPrice('');
    setError('');
  }

  return (
    <div className="container py-4">
      <h1 className="mb-4">👟 ShoeAR Supplier Portal</h1>

      {/* ④ THE FORM */}
      <form onSubmit={handleSubmit} className="card card-body mb-4 bg-light">
        {error && <div className="alert alert-danger py-2">{error}</div>}
        <div className="row g-2">
          <div className="col-md-4">
            <input
              type="text"
              maxLength="100"
              className="form-control"
              placeholder="Shoe name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>
          <div className="col-md-3">
            <input
              type="text"
              maxLength="100"
              className="form-control"
              placeholder="Brand"
              value={brand}
              onChange={(e) => setBrand(e.target.value)}
              required
            />
          </div>
          <div className="col-md-3">
            <input
              type="number"
              min="0.00"
              max="100000"
              step="0.01"
              maxLength="50"
              className="form-control"
              placeholder="Price (RM)"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              required
            />
          </div>
          <div className="col-md-2">
            <button type="submit" className="btn btn-primary w-100">
              + Add
            </button>
          </div>
        </div>
      </form>

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
                  name={shoe.name}
                  brand={shoe.brand}
                  price={shoe.price}
                />
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}

export default App;