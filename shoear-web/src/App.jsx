import { Routes, Route, Link, Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from './features/auth/AuthContext';
import ProductsPage from './features/products/pages/ProductsPage';
import ReportsPage from './features/reports/pages/ReportsPage';
import LoginPage from './features/auth/pages/LoginPage';
import ProtectedRoute, { homePathFor } from './features/auth/ProtectedRoute';
import RegisterPage from './features/auth/pages/RegisterPage';
import ProductDetailPage from './features/products/pages/ProductDetailPage';
import AddProductPage from './features/products/pages/AddProductPage';
import AdminDashboardPage from './features/admin/pages/AdminDashboardPage';
import AdminProductApprovalsPage from './features/admin/pages/AdminProductApprovalsPage';
import AdminCategoriesPage from './features/admin/pages/AdminCategoriesPage';
import AdminUsersPage from './features/admin/pages/AdminUsersPage';
import ProfilePage from './features/profile/ProfilePage';
import Avatar from './components/Avatar';

function App() {
  const { user, logout } = useAuth();   // 👈 tune in to the auth broadcast
  const navigate = useNavigate();

  const isAdmin = user?.role === 'Admin';

  function handleLogout() {
    logout();
    navigate('/login');
  }

  return (
    <>
      {/* the top bar only makes sense once you're signed in; the login and
          register pages are full-screen on their own */}
      {user && (
        <nav className="navbar navbar-expand navbar-dark bg-dark px-4">
          <span className="navbar-brand">👟 ShoeAR {isAdmin ? 'Admin' : 'Supplier'}</span>

          {/* admins manage approvals; suppliers manage their catalogue */}
          <div className="navbar-nav me-auto">
            {isAdmin ? (
              <>
                <Link className="nav-link" to="/admin">Suppliers</Link>
                <Link className="nav-link" to="/admin/users">Users</Link>
                <Link className="nav-link" to="/admin/products">Products</Link>
                <Link className="nav-link" to="/admin/categories">Categories</Link>
              </>
            ) : (
              <>
                <Link className="nav-link" to="/products">Products</Link>
                <Link className="nav-link" to="/reports">Reports</Link>
              </>
            )}
          </div>

          <div className="navbar-nav align-items-center">
            <Link to="/profile"
              className="navbar-text text-light me-3 d-inline-flex align-items-center text-decoration-none">
              <Avatar name={user.fullName} size={32} className="me-2" />
              <span>Hi, {user.fullName}</span>
            </Link>
            <button className="btn btn-outline-light btn-sm" onClick={handleLogout}>
              Logout
            </button>
          </div>
        </nav>
      )}

      <Routes>
        <Route path="/login" element={<LoginPage variant="supplier" />} />
        <Route path="/admin/login" element={<LoginPage variant="admin" />} />
        <Route path="/register" element={<RegisterPage />} />

        {/* "/" sends each user to their own home */}
        <Route path="/" element={
          <ProtectedRoute><Navigate to={homePathFor(user)} replace /></ProtectedRoute>
        } />

        {/* admin */}
        <Route path="/admin" element={
          <ProtectedRoute role="Admin"><AdminDashboardPage /></ProtectedRoute>
        } />
        <Route path="/admin/products" element={
          <ProtectedRoute role="Admin"><AdminProductApprovalsPage /></ProtectedRoute>
        } />
        <Route path="/admin/categories" element={
          <ProtectedRoute role="Admin"><AdminCategoriesPage /></ProtectedRoute>
        } />
        <Route path="/admin/users" element={
          <ProtectedRoute role="Admin"><AdminUsersPage /></ProtectedRoute>
        } />

        {/* any signed-in user's own profile */}
        <Route path="/profile" element={
          <ProtectedRoute><ProfilePage /></ProtectedRoute>
        } />

        {/* supplier */}
        <Route path="/products" element={
          <ProtectedRoute role="Supplier"><ProductsPage /></ProtectedRoute>
        } />
        <Route path="/products/new" element={
          <ProtectedRoute role="Supplier"><AddProductPage /></ProtectedRoute>
        } />
        <Route path="/products/:id" element={
          <ProtectedRoute role="Supplier"><ProductDetailPage /></ProtectedRoute>
        } />
        <Route path="/reports" element={
          <ProtectedRoute role="Supplier"><ReportsPage /></ProtectedRoute>
        } />
      </Routes>
    </>
  );
}

export default App;
