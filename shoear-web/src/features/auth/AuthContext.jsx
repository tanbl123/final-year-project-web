import { createContext, useContext, useState } from 'react';
import { login as loginRequest, logout as logoutRequest } from './authService';

// 1) create the "broadcast channel"
const AuthContext = createContext(null);

// 2) the Provider holds the auth state and shares it with everything inside it
export function AuthProvider({ children }) {
  // read any saved user once, so a page refresh keeps you logged in
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('user');
    return saved ? JSON.parse(saved) : null;
  });

  async function login(identifier, password) {
    const result = await loginRequest(identifier, password);   // identifier = email or username
    localStorage.setItem('token', result.token);
    localStorage.setItem('user', JSON.stringify(result.user));
    setUser(result.user);        // update global state → whole app re-renders
    return result;
  }

  function logout() {
    logoutRequest();             // clears localStorage
    setUser(null);               // update global state
  }

  // merge fields into the cached user (e.g. after a profile edit) and persist
  function updateUser(patch) {
    setUser((prev) => {
      const next = { ...prev, ...patch };
      localStorage.setItem('user', JSON.stringify(next));
      return next;
    });
  }

  // everything we want to share with the app
  const value = { user, login, logout, updateUser };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// 3) a tiny helper hook so any component can grab the auth info easily
export function useAuth() {
  return useContext(AuthContext);
}