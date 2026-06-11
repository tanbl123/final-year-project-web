// Fake authentication. Later these call your real PHP API.
export function login(email, password) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      // pretend the backend checked the credentials
      if (email === 'supplier@shoear.com' && password === 'password123') {
        resolve({
          token: 'fake-jwt-token-abc123',
          user: { id: 'USR0001', name: 'Demo Supplier', role: 'Supplier' },
        });
      } else {
        reject(new Error('Invalid email or password.'));
      }
    }, 800);
  });
}

export function logout() {
  localStorage.removeItem('token');
  localStorage.removeItem('user');
}

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