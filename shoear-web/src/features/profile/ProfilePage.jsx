import { useEffect, useState } from 'react';
import { getMe, updateMe, changePassword } from '../auth/authService';
import { useAuth } from '../auth/AuthContext';
import Avatar from '../../components/Avatar';
import Toast from '../../components/Toast';

const EMPTY_PW = { currentPassword: '', newPassword: '', confirmPassword: '' };

const STATUS_COLORS = {
  Active: 'success', Pending: 'warning', Suspended: 'secondary',
  Rejected: 'danger', Deleted: 'dark',
};
const roleLabel = (r) => (r === 'DeliveryPersonnel' ? 'Delivery' : r);

function ProfilePage() {
  const { updateUser } = useAuth();
  const [me, setMe] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');

  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState({ fullName: '', phoneNumber: '' });
  const [saving, setSaving] = useState(false);

  const [pwOpen, setPwOpen] = useState(false);
  const [pw, setPw] = useState(EMPTY_PW);
  const [pwError, setPwError] = useState('');
  const [pwSaving, setPwSaving] = useState(false);

  useEffect(() => {
    let active = true;
    getMe()
      .then((data) => { if (active) setMe(data); })
      .catch((err) => { if (active) setError(err.message); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, []);

  function startEdit() {
    setForm({ fullName: me.fullName, phoneNumber: me.phoneNumber || '' });
    setEditing(true);
  }

  async function save(e) {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      const saved = await updateMe(form);
      setMe((m) => ({ ...m, ...saved }));
      updateUser({ fullName: saved.fullName });   // refresh the navbar greeting
      setEditing(false);
      setToast('Profile updated.');
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  }

  function closePw() {
    setPwOpen(false);
    setPw(EMPTY_PW);
    setPwError('');
  }

  async function savePassword(e) {
    e.preventDefault();
    setPwError('');
    if (pw.newPassword !== pw.confirmPassword) {
      setPwError('New password and confirmation do not match.');
      return;
    }
    setPwSaving(true);
    try {
      await changePassword(pw.currentPassword, pw.newPassword);
      closePw();
      setToast('Password changed.');
    } catch (err) {
      setPwError(err.message);
    } finally {
      setPwSaving(false);
    }
  }

  if (loading) return <div className="container py-4"><p className="text-muted">Loading…</p></div>;
  if (!me) {
    return (
      <div className="container py-4">
        <div className="alert alert-danger">{error || 'Could not load your profile.'}</div>
      </div>
    );
  }

  return (
    <div className="container py-4 text-start" style={{ maxWidth: 720 }}>
      <h1 className="mb-4">My Profile</h1>

      {error && (
        <div className="alert alert-danger py-2 d-flex justify-content-between align-items-center">
          <span>{error}</span>
          <button type="button" className="btn-close" onClick={() => setError('')}></button>
        </div>
      )}

      <div className="card">
        <div className="card-body">
          {/* header: big avatar + name */}
          <div className="d-flex align-items-center gap-3 mb-4">
            <Avatar name={me.fullName} size={72} />
            <div>
              <h4 className="mb-0">{me.fullName}</h4>
              <div className="text-muted">
                @{me.username}
                <span className={`badge ms-2 text-bg-light`}>{roleLabel(me.role)}</span>
                <span className={`badge ms-1 text-bg-${STATUS_COLORS[me.status] || 'secondary'}`}>{me.status}</span>
              </div>
            </div>
          </div>

          {editing ? (
            <form onSubmit={save}>
              <div className="mb-3">
                <label className="form-label">Full name</label>
                <input type="text" className="form-control" maxLength="100" required autoFocus
                  value={form.fullName}
                  onChange={(e) => setForm((f) => ({ ...f, fullName: e.target.value }))} />
              </div>
              <div className="mb-3">
                <label className="form-label">Phone number</label>
                <input type="text" className="form-control" maxLength="30" required
                  value={form.phoneNumber}
                  onChange={(e) => setForm((f) => ({ ...f, phoneNumber: e.target.value }))} />
              </div>
              <div className="d-flex gap-2">
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Saving…' : 'Save changes'}
                </button>
                <button type="button" className="btn btn-outline-secondary"
                  onClick={() => setEditing(false)} disabled={saving}>Cancel</button>
              </div>
            </form>
          ) : (
            <>
              <dl className="row mb-0">
                <dt className="col-sm-4">Email</dt>
                <dd className="col-sm-8" style={{ overflowWrap: 'anywhere' }}>{me.email}</dd>
                <dt className="col-sm-4">Phone</dt>
                <dd className="col-sm-8">{me.phoneNumber || <span className="text-muted">—</span>}</dd>

                {me.role === 'Supplier' && me.profile && (
                  <>
                    <dt className="col-sm-4">Company</dt>
                    <dd className="col-sm-8">{me.profile.companyName}</dd>
                    <dt className="col-sm-4">Company address</dt>
                    <dd className="col-sm-8">{me.profile.companyAddress}</dd>
                  </>
                )}
                {me.role === 'Customer' && me.profile && (
                  <>
                    <dt className="col-sm-4">Shipping address</dt>
                    <dd className="col-sm-8">{me.profile.shippingAddress || <span className="text-muted">—</span>}</dd>
                  </>
                )}
                {me.role === 'DeliveryPersonnel' && me.profile && (
                  <>
                    <dt className="col-sm-4">Vehicle</dt>
                    <dd className="col-sm-8">{me.profile.vehicleInfo || <span className="text-muted">—</span>}</dd>
                  </>
                )}

                <dt className="col-sm-4">Member since</dt>
                <dd className="col-sm-8">{new Date(me.created_at).toLocaleDateString()}</dd>
              </dl>
              <hr />
              <button className="btn btn-primary" onClick={startEdit}>Edit profile</button>
            </>
          )}
        </div>
      </div>

      {/* change password */}
      <div className="card mt-4">
        <div className="card-body">
          <div className="d-flex justify-content-between align-items-center">
            <div>
              <h5 className="mb-0">Password</h5>
              <small className="text-muted">Change the password you use to sign in.</small>
            </div>
            {!pwOpen && (
              <button className="btn btn-outline-primary" onClick={() => setPwOpen(true)}>
                Change password
              </button>
            )}
          </div>

          {pwOpen && (
            <form className="mt-3" onSubmit={savePassword}>
              {pwError && (
                <div className="alert alert-danger py-2">{pwError}</div>
              )}
              <div className="mb-3">
                <label className="form-label">Current password</label>
                <input type="password" className="form-control" required autoFocus
                  autoComplete="current-password"
                  value={pw.currentPassword}
                  onChange={(e) => setPw((p) => ({ ...p, currentPassword: e.target.value }))} />
              </div>
              <div className="mb-3">
                <label className="form-label">New password</label>
                <input type="password" className="form-control" required
                  autoComplete="new-password"
                  value={pw.newPassword}
                  onChange={(e) => setPw((p) => ({ ...p, newPassword: e.target.value }))} />
                <div className="form-text">
                  At least 8 characters with upper &amp; lower case, a number and a special character.
                </div>
              </div>
              <div className="mb-3">
                <label className="form-label">Confirm new password</label>
                <input type="password" className="form-control" required
                  autoComplete="new-password"
                  value={pw.confirmPassword}
                  onChange={(e) => setPw((p) => ({ ...p, confirmPassword: e.target.value }))} />
              </div>
              <div className="d-flex gap-2">
                <button type="submit" className="btn btn-primary" disabled={pwSaving}>
                  {pwSaving ? 'Saving…' : 'Update password'}
                </button>
                <button type="button" className="btn btn-outline-secondary"
                  onClick={closePw} disabled={pwSaving}>Cancel</button>
              </div>
            </form>
          )}
        </div>
      </div>

      <Toast message={toast} onClose={() => setToast('')} />
    </div>
  );
}

export default ProfilePage;
