// All product data logic lives here.
// Today it's fake; later, these become real calls to your PHP API.
export function fetchProducts() {
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