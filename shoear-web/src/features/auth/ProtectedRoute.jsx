import { Navigate } from 'react-router-dom';
import { useAuth } from './AuthContext';

// Where a logged-in user belongs by default, based on their role.
export function homePathFor(user) {
  return user?.role === 'Admin' ? '/admin' : '/products';
}

function ProtectedRoute({ children, role }) {
  const { user } = useAuth();

  // not logged in? bounce to login.
  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // logged in but wrong role? send them to their own home.
  if (role && user.role !== role) {
    return <Navigate to={homePathFor(user)} replace />;
  }

  return children;
}

export default ProtectedRoute;
