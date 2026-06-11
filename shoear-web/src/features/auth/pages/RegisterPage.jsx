import { useState } from 'react';
import { Link } from 'react-router-dom';
import { register } from '../authService';

function RegisterPage() {
  const [form, setForm] = useState({
    fullName: '', username: '', email: '', phoneNumber: '',
    companyName: '', companyAddress: '', password: '', confirm: '',
  });
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [done, setDone] = useState(false);   // show the "pending approval" screen

  // one handler updates whichever field changed (by its name)
  function handleChange(event) {
    const { name, value } = event.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setError('');

    if (form.password.length < 6) { setError('Password must be at least 6 characters.'); return; }
    if (form.password !== form.confirm) { setError('Passwords do not match.'); return; }

    setIsSubmitting(true);
    try {
      // send everything the backend needs (not the confirm field)
      await register({
        fullName: form.fullName.trim(),
        username: form.username.trim(),
        email: form.email.trim(),
        phoneNumber: form.phoneNumber.trim(),
        companyName: form.companyName.trim(),
        companyAddress: form.companyAddress.trim(),
        password: form.password,
      });
      setDone(true);   // success → show pending-approval message
    } catch (err) {
      setError(err.message);
    } finally {
      setIsSubmitting(false);
    }
  }

  // after a successful registration, the account is Pending — they can't log
  // in yet, so show a clear "wait for approval" message instead of the form.
  if (done) {
    return (
      <div className="container py-5 text-center" style={{ maxWidth: '480px' }}>
        <h1 className="mb-3">✅ Registration submitted</h1>
        <p className="text-muted">
          Your supplier account is <strong>pending admin approval</strong>. You'll be
          able to log in once an admin approves it.
        </p>
        <Link to="/login" className="btn btn-primary mt-2">Back to Login</Link>
      </div>
    );
  }

  return (
    <div className="container py-5" style={{ maxWidth: '520px' }}>
      <h1 className="mb-4 text-center">👟 Supplier Registration</h1>
      <form onSubmit={handleSubmit} className="card card-body shadow-sm">
        {error && <div className="alert alert-danger py-2">{error}</div>}

        <div className="mb-3">
          <label className="form-label">Full name</label>
          <input name="fullName" className="form-control" value={form.fullName} onChange={handleChange} required />
        </div>
        <div className="row">
          <div className="col-md-6 mb-3">
            <label className="form-label">Username</label>
            <input name="username" className="form-control" value={form.username} onChange={handleChange} required />
          </div>
          <div className="col-md-6 mb-3">
            <label className="form-label">Phone number</label>
            <input name="phoneNumber" className="form-control" value={form.phoneNumber} onChange={handleChange} required />
          </div>
        </div>
        <div className="mb-3">
          <label className="form-label">Email</label>
          <input type="email" name="email" className="form-control" value={form.email} onChange={handleChange} required />
        </div>
        <div className="mb-3">
          <label className="form-label">Company name</label>
          <input name="companyName" className="form-control" value={form.companyName} onChange={handleChange} required />
        </div>
        <div className="mb-3">
          <label className="form-label">Company address</label>
          <input name="companyAddress" className="form-control" value={form.companyAddress} onChange={handleChange} required />
        </div>
        <div className="row">
          <div className="col-md-6 mb-3">
            <label className="form-label">Password</label>
            <input type="password" name="password" className="form-control" value={form.password} onChange={handleChange} required />
          </div>
          <div className="col-md-6 mb-3">
            <label className="form-label">Confirm password</label>
            <input type="password" name="confirm" className="form-control" value={form.confirm} onChange={handleChange} required />
          </div>
        </div>

        <button type="submit" className="btn btn-primary w-100" disabled={isSubmitting}>
          {isSubmitting ? 'Registering...' : 'Register'}
        </button>
      </form>
      <p className="text-center mt-3">
        Already have an account? <Link to="/login">Login</Link>
      </p>
    </div>
  );
}

export default RegisterPage;
