const PRODUCTS = [
  { id: 'PRD0001', name: 'Air Zoom Pegasus', brand: 'Nike',   price: 399 },
  { id: 'PRD0002', name: 'UltraBoost 22',    brand: 'Adidas', price: 549 },
  { id: 'PRD0003', name: 'Gel-Kayano',       brand: 'Asics',  price: 459 },
];

export function fetchProducts() {
  return new Promise((resolve) => setTimeout(() => resolve(PRODUCTS), 1000));
}

export function fetchProductById(id) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      const found = PRODUCTS.find((p) => p.id === id);
      if (found) resolve(found);
      else reject(new Error('Product not found.'));
    }, 500);
  });
}