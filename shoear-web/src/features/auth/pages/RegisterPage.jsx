import { useState } from 'react';
import { Link } from 'react-router-dom';
import { register } from '../authService';

// Bootstrap Icons eye / eye-slash, inlined as SVG so we don't pull in the
// whole icon font just for one glyph.
function EyeIcon({ off }) {
  return off ? (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
      <path d="m10.79 12.912-1.614-1.615a3.5 3.5 0 0 1-4.474-4.474l-2.06-2.06C.938 6.278 0 8 0 8s3 5.5 8 5.5a7 7 0 0 0 2.79-.588M5.21 3.088A7 7 0 0 1 8 2.5c5 0 8 5.5 8 5.5s-.939 1.721-2.641 3.238l-2.062-2.062a3.5 3.5 0 0 0-4.474-4.474z" />
      <path d="M5.525 7.646a2.5 2.5 0 0 0 2.829 2.829zm4.95.708-2.829-2.83a2.5 2.5 0 0 1 2.829 2.829z" />
      <path d="M2.354 1.646 1.646 2.354l12 12 .708-.708z" />
    </svg>
  ) : (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
      <path d="M16 8s-3-5.5-8-5.5S0 8 0 8s3 5.5 8 5.5S16 8 16 8M1.173 8a13 13 0 0 1 1.66-2.043C4.12 4.668 5.88 3.5 8 3.5s3.879 1.168 5.168 2.457A13 13 0 0 1 14.828 8q-.086.13-.195.288c-.335.48-.83 1.12-1.465 1.755C11.879 11.332 10.119 12.5 8 12.5s-3.879-1.168-5.168-2.457A13 13 0 0 1 1.172 8z" />
      <path d="M8 5.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5M4.5 8a3.5 3.5 0 1 1 7 0 3.5 3.5 0 0 1-7 0" />
    </svg>
  );
}

// Password policy: 8+ chars with at least one lowercase, uppercase, digit
// and special character. Returns an error string, or '' when it's valid.
function validatePassword(pw) {
  if (pw.length < 8) return 'Password must be at least 8 characters.';
  if (!/[a-z]/.test(pw)) return 'Password must include a lowercase letter.';
  if (!/[A-Z]/.test(pw)) return 'Password must include an uppercase letter.';
  if (!/[0-9]/.test(pw)) return 'Password must include a number.';
  if (!/[^a-zA-Z0-9]/.test(pw)) return 'Password must include a special character.';
  return '';
}

// Validate the whole form, returning a { field: message } object.
// An empty object means everything passed.
function validateForm(form) {
  const errors = {};

  if (form.companyName.trim() === '') errors.companyName = 'Company name is required.';
  if (form.username.trim() === '') errors.username = 'Username is required.';

  if (form.email.trim() === '') {
    errors.email = 'Email is required.';
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email.trim())) {
    errors.email = 'Please enter a valid email.';
  }

  // E.164: optional leading +, country code, up to 15 digits total
  if (form.phoneNumber.trim() === '') {
    errors.phoneNumber = 'Phone number is required.';
  } else if (!/^\+?[1-9]\d{7,14}$/.test(form.phoneNumber.trim())) {
    errors.phoneNumber = 'Enter a valid phone number in international format, e.g. +60123456789.';
  }

  if (form.companyAddress.trim() === '') errors.companyAddress = 'Company address is required.';

  const pwError = validatePassword(form.password);
  if (pwError) errors.password = pwError;

  if (form.confirm === '') {
    errors.confirm = 'Please confirm your password.';
  } else if (form.password !== form.confirm) {
    errors.confirm = 'Passwords do not match.';
  }

  return errors;
}

// Set or clear a single field's error on an errors object (mutates it),
// reusing the same rules as the full-form validation.
function applyFieldError(errors, name, form) {
  const msg = validateForm(form)[name];
  if (msg) errors[name] = msg;
  else delete errors[name];
}

function RegisterPage() {
  const [form, setForm] = useState({
    companyName: '', username: '', email: '', phoneNumber: '',
    companyAddress: '', password: '', confirm: '',
  });
  const [errors, setErrors] = useState({});       // per-field messages
  const [formError, setFormError] = useState(''); // general/server fallback
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [done, setDone] = useState(false);        // show the "pending approval" screen
  const [shown, setShown] = useState({ password: false, confirm: false }); // show/hide toggles

  function toggleShown(name) {
    setShown((prev) => ({ ...prev, [name]: !prev[name] }));
  }

  // update the changed field; if it (or the linked confirm field) is already
  // showing an error, re-check it live so the message updates as you fix it
  function handleChange(event) {
    const { name, value } = event.target;
    const nextForm = { ...form, [name]: value };
    setForm(nextForm);

    setErrors((prev) => {
      const next = { ...prev };
      if (name in prev) applyFieldError(next, name, nextForm);
      // password & confirm are linked — keep the confirm error in sync
      if (name === 'password' && 'confirm' in prev) applyFieldError(next, 'confirm', nextForm);
      return next;
    });
  }

  // validate a single field when the user leaves it (real-time, on blur)
  function handleBlur(event) {
    const { name } = event.target;
    setErrors((prev) => {
      const next = { ...prev };
      applyFieldError(next, name, form);
      return next;
    });
  }

  async function handleSubmit(event) {
    event.preventDefault();   // AJAX submit — no page reload
    setFormError('');

    const found = validateForm(form);
    if (Object.keys(found).length > 0) {
      setErrors(found);
      return;
    }
    setErrors({});

    setIsSubmitting(true);
    try {
      // send everything the backend needs (not the confirm field)
      await register({
        username: form.username.trim(),
        email: form.email.trim(),
        phoneNumber: form.phoneNumber.trim(),
        companyName: form.companyName.trim(),
        companyAddress: form.companyAddress.trim(),
        password: form.password,
      });
      setDone(true);   // success → show pending-approval message
    } catch (err) {
      // map known duplicate errors back onto the offending field
      const msg = err.message || 'Something went wrong. Please try again.';
      if (/email/i.test(msg)) setErrors({ email: msg });
      else if (/username/i.test(msg)) setErrors({ username: msg });
      else setFormError(msg);
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

  // small helper so every field renders the same way (input + inline error)
  function field(name, label, type = 'text') {
    return (
      <div className="mb-3">
        <label className="form-label">{label}</label>
        <input
          type={type}
          name={name}
          className={`form-control ${errors[name] ? 'is-invalid' : ''}`}
          value={form[name]}
          onChange={handleChange}
          onBlur={handleBlur}
        />
        {errors[name] && <div className="invalid-feedback">{errors[name]}</div>}
      </div>
    );
  }

  // password fields get our own Show/Hide toggle (the browser's native reveal
  // icon is inconsistent and clashes with the validation icon). has-validation
  // lets Bootstrap show the inline error correctly inside an input-group.
  function passwordField(name, label) {
    const isShown = shown[name];
    return (
      <div className="mb-3">
        <label className="form-label">{label}</label>
        <div className="input-group has-validation">
          <input
            type={isShown ? 'text' : 'password'}
            name={name}
            className={`form-control ${errors[name] ? 'is-invalid' : ''}`}
            value={form[name]}
            onChange={handleChange}
            onBlur={handleBlur}
            style={{ backgroundImage: 'none' }}
          />
          <button
            type="button"
            className="btn btn-outline-secondary d-flex align-items-center"
            onClick={() => toggleShown(name)}
            tabIndex={-1}
            aria-label={isShown ? 'Hide password' : 'Show password'}
          >
            <EyeIcon off={isShown} />
          </button>
          {errors[name] && <div className="invalid-feedback">{errors[name]}</div>}
        </div>
      </div>
    );
  }

  return (
    <div className="container py-5" style={{ maxWidth: '440px' }}>
      <h1 className="mb-4 text-center">👟 Supplier Registration</h1>
      <form onSubmit={handleSubmit} className="card card-body shadow-sm text-start" noValidate>
        {formError && <div className="alert alert-danger py-2">{formError}</div>}

        {field('companyName', 'Company name')}
        {field('username', 'Username')}
        {field('email', 'Email', 'email')}
        {field('phoneNumber', 'Phone number', 'tel')}
        {field('companyAddress', 'Company address')}
        {passwordField('password', 'Password')}
        {passwordField('confirm', 'Confirm password')}

        <button type="submit" className="btn btn-primary w-100 text-center" disabled={isSubmitting}>
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
