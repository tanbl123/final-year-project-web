import { Routes, Route, Link, useNavigate } from 'react-router-dom';
import { useAuth } from './features/auth/AuthContext';
import ProductsPage from './features/products/pages/ProductsPage';
import ReportsPage from './features/reports/pages/ReportsPage';
import LoginPage from './features/auth/pages/LoginPage';
import ProtectedRoute from './features/auth/ProtectedRoute';
import RegisterPage from './features/auth/pages/RegisterPage';
import ProductDetailPage from './features/products/pages/ProductDetailPage';

function App() {
  const { user, logout } = useAuth();   // 👈 tune in to the auth broadcast
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate('/login');
  }

  return (
    <>
      <nav className="navbar navbar-expand navbar-dark bg-dark px-4">
        <span className="navbar-brand">👟 ShoeAR Supplier</span>

        <div className="navbar-nav me-auto">
          <Link className="nav-link" to="/products">Products</Link>
          <Link className="nav-link" to="/reports">Reports</Link>
        </div>

        {/* show different things depending on login status */}
        <div className="navbar-nav">
          {user ? (
            <>
              <span className="navbar-text text-light me-3">Hi, {user.fullName}</span>
              <button className="btn btn-outline-light btn-sm" onClick={handleLogout}>
                Logout
              </button>
            </>
          ) : (
            <Link className="nav-link" to="/login">Login</Link>
          )}
        </div>
      </nav>

      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        
        <Route path="/" element={
          <ProtectedRoute><ProductsPage /></ProtectedRoute>
        } />
        <Route path="/products" element={
          <ProtectedRoute><ProductsPage /></ProtectedRoute>
        } />
        <Route path="/products/:id" element={
          <ProtectedRoute><ProductDetailPage /></ProtectedRoute>
        } />
        <Route path="/reports" element={
          <ProtectedRoute><ReportsPage /></ProtectedRoute>
        } />
      </Routes>
    </>
  );
}

export default App;