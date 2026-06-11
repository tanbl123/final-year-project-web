import { apiPost } from '../../api/client';

// REAL login against the PHP API (POST /auth/login).
// Returns { token, user } on success, or throws with the server's error message.
export function login(email, password) {
  return apiPost('/auth/login', { email, password });
}

// Logout is client-side: just discard the saved token + user.
export function logout() {
  localStorage.removeItem('token');
  localStorage.removeItem('user');
}

// TODO: wire to POST /auth/register once that backend endpoint exists.
// Kept mocked for now so the Register page still works.
export function register(data) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (!data.email.includes('@')) {
        reject(new Error('Please enter a valid email.'));
      } else {
        resolve({ message: 'Registration successful. Please log in.' });
      }
    }, 800);
  });
}
