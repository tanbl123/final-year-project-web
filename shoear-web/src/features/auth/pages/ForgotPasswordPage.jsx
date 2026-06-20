import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { forgotPassword, resetPassword } from '../authService';
import EyeIcon from '../../../components/EyeIcon';

// Same password policy as registration: 8+ chars with a lowercase, uppercase,
// digit and special character. Returns an error string, or '' when valid.
function validatePassword(pw) {
  if (pw.length < 8) return 'Password must be at least 8 characters.';
  if (!/[a-z]/.test(pw)) return 'Password must include a lowercase letter.';
  if (!/[A-Z]/.test(pw)) return 'Password must include an uppercase letter.';
  if (!/[0-9]/.test(pw)) return 'Password must include a number.';
  if (!/[^a-zA-Z0-9]/.test(pw)) return 'Password must include a special character.';
  return '';
}

// "Forgot password" flow:
//   step 'request' → enter email, we email a 6-digit code
//   step 'reset'   → enter the code + a new password
// Mirrors the registration email-verification flow (same code rules).
function ForgotPasswordPage() {
  const [step, setStep] = useState('request');   // 'request' → 'reset'
  const [email, setEmail] = useState('');
  const [emailError, setEmailError] = useState('');
  const [sending, setSending] = useState(false);

  const [code, setCode] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [shown, setShown] = useState({ password: false, confirm: false });
  const [resetError, setResetError] = useState('');   // error shown on the reset screen
  const [info, setInfo] = useState('');               // success/notice banner
  const [resetting, setResetting] = useState(false);
  const [resending, setResending] = useState(false);
  const [resendIn, setResendIn] = useState(0);
  const [done, setDone] = useState(false);

  // tick the resend cooldown down to zero
  useEffect(() => {
    if (resendIn <= 0) return undefined;
    const t = setTimeout(() => setResendIn((n) => n - 1), 1000);
    return () => clearTimeout(t);
  }, [resendIn]);

  function toggleShown(name) {
    setShown((prev) => ({ ...prev, [name]: !prev[name] }));
  }

  // Step 1 → ask the server to email a code, then move to the reset screen.
  async function handleRequest(event) {
    event.preventDefault();
    setEmailError('');
    if (email.trim() === '' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      setEmailError('Please enter a valid email.');
      return;
    }
    setSending(true);
    try {
      const res = await forgotPassword(email.trim());
      // generic message (doesn't reveal whether the account exists)
      setInfo(res?.message || 'If an account exists for that email, a reset code has been sent.');
      setResetError('');
      setCode('');
      setStep('reset');
      setResendIn(60);   // mirror the backend's 60s resend cooldown
    } catch (err) {
      setEmailError(err.message || 'Something went wrong. Please try again.');
    } finally {
      setSending(false);
    }
  }

  // Step 2 → submit the code + new password.
  async function handleReset(event) {
    event.preventDefault();
    setResetError('');
    if (!/^\d{6}$/.test(code.trim())) {
      setResetError('Enter the 6-digit code from your email.');
      return;
    }
    const pwError = validatePassword(password);
    if (pwError) { setResetError(pwError); return; }
    if (password !== confirm) { setResetError('Passwords do not match.'); return; }

    setResetting(true);
    try {
      await resetPassword(email.trim(), code.trim(), password);
      setDone(true);
    } catch (err) {
      setResetError(err.message || 'Something went wrong. Please try again.');
    } finally {
      setResetting(false);
    }
  }

  // Resend a fresh code (respecting the cooldown).
  async function handleResend() {
    if (resendIn > 0 || resending) return;
    setResetError('');
    setInfo('');
    setResending(true);
    try {
      await forgotPassword(email.trim());
      setResendIn(60);
      setInfo('A new code has been sent to your email.');
    } catch (err) {
      setResetError(err.message || 'Could not resend the code. Please try again.');
    } finally {
      setResending(false);
    }
  }

  // success screen
  if (done) {
    return (
      <div className="container py-5 text-center" style={{ maxWidth: '480px' }}>
        <h1 className="mb-3">✅ Password reset</h1>
        <p className="text-muted">
          Your password has been updated. You can now log in with your new password.
        </p>
        <Link to="/login" className="btn btn-primary mt-2">Back to Login</Link>
      </div>
    );
  }

  // a password field with a Show/Hide toggle (same pattern as the other forms)
  function passwordField(name, label, value, setter) {
    const isShown = shown[name];
    return (
      <div className="mb-3">
        <label className="form-label">{label}</label>
        <div className="input-group">
          <input
            type={isShown ? 'text' : 'password'}
            className="form-control"
            value={value}
            onChange={(e) => { setter(e.target.value); setResetError(''); }}
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
        </div>
      </div>
    );
  }

  // step 1: request a code
  if (step === 'request') {
    return (
      <div className="container py-5" style={{ maxWidth: '420px' }}>
        <h1 className="mb-4 text-center">🔑 Forgot password</h1>
        <form onSubmit={handleRequest} className="card card-body shadow-sm text-start" noValidate>
          <p className="text-muted">
            Enter your account email and we'll send you a 6-digit code to reset your password.
          </p>
          <div className="mb-3">
            <label className="form-label">Email</label>
            <input
              type="email"
              autoComplete="email"
              autoFocus
              className={`form-control ${emailError ? 'is-invalid' : ''}`}
              value={email}
              onChange={(e) => { setEmail(e.target.value); setEmailError(''); }}
            />
            {emailError && <div className="invalid-feedback d-block">{emailError}</div>}
          </div>
          <button type="submit" className="btn btn-primary w-100 text-center" disabled={sending}>
            {sending ? 'Sending code...' : 'Send reset code'}
          </button>
        </form>
        <p className="text-center mt-3">
          Remembered it? <Link to="/login">Back to Login</Link>
        </p>
      </div>
    );
  }

  // step 2: enter the code + new password
  return (
    <div className="container py-5" style={{ maxWidth: '440px' }}>
      <h1 className="mb-3 text-center">🔑 Reset password</h1>
      <form onSubmit={handleReset} className="card card-body shadow-sm text-start" noValidate>
        <p className="text-muted">
          We've sent a 6-digit code to <strong>{email.trim()}</strong> (if an account exists).
          Enter it below with your new password.
        </p>
        {info && <div className="alert alert-success py-2">{info}</div>}
        {resetError && <div className="alert alert-danger py-2">{resetError}</div>}

        <div className="mb-3">
          <label className="form-label">Verification code</label>
          <input
            type="text"
            inputMode="numeric"
            autoComplete="one-time-code"
            maxLength={6}
            autoFocus
            className="form-control text-center"
            style={{ letterSpacing: '0.5em', fontSize: '1.4rem' }}
            value={code}
            onChange={(e) => { setCode(e.target.value.replace(/\D/g, '').slice(0, 6)); setResetError(''); }}
          />
        </div>

        {passwordField('password', 'New password', password, setPassword)}
        {passwordField('confirm', 'Confirm new password', confirm, setConfirm)}

        <button type="submit" className="btn btn-primary w-100 text-center" disabled={resetting}>
          {resetting ? 'Resetting...' : 'Reset password'}
        </button>

        <div className="d-flex justify-content-between align-items-center mt-3">
          <button type="button" className="btn btn-link p-0"
            onClick={() => { setStep('request'); setResetError(''); setInfo(''); }}>
            ← Change email
          </button>
          <button type="button" className="btn btn-link p-0"
            onClick={handleResend} disabled={resendIn > 0 || resending}>
            {resending ? 'Sending…' : resendIn > 0 ? `Resend code (${resendIn}s)` : 'Resend code'}
          </button>
        </div>
      </form>
    </div>
  );
}

export default ForgotPasswordPage;
