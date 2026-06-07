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

  useEffect(() => {
    fakeFetchProducts().then((data) => {
      setProducts(data);
      setIsLoading(false);
    });
  }, []);

  return (
    <div className="container py-4">
      <h1 className="mb-4">👟 ShoeAR Supplier Portal</h1>

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