import { Routes, Route, Link } from 'react-router-dom';
import ProductsPage from './features/products/pages/ProductsPage';
import ReportsPage from './features/reports/pages/ReportsPage';

function App() {
  return (
    <>
      {/* top navigation bar — shows on every page */}
      <nav className="navbar navbar-expand navbar-dark bg-dark px-4">
        <span className="navbar-brand">👟 ShoeAR Supplier</span>
        <div className="navbar-nav">
          <Link className="nav-link" to="/products">Products</Link>
          <Link className="nav-link" to="/reports">Reports</Link>
        </div>
      </nav>

      {/* the routing table: which URL shows which page */}
      <Routes>
        <Route path="/" element={<ProductsPage />} />
        <Route path="/products" element={<ProductsPage />} />
        <Route path="/reports" element={<ReportsPage />} />
      </Routes>
    </>
  );
}

export default App;