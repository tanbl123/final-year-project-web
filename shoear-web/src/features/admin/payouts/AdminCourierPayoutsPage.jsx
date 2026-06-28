import { useEffect, useState } from 'react';
import { getCourierPayouts, payCourier } from '../adminService';

// Courier payouts — each active courier's accrued per-delivery earnings, with a
// one-click Stripe payout of their pending balance. A courier must have finished
// connecting their Stripe payout account before they can be paid.
function AdminCourierPayoutsPage() {
  const [couriers, setCouriers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [busyId, setBusyId] = useState('');

  function load() {
    setLoading(true);
    getCourierPayouts()
      .then((data) => setCouriers(data.couriers))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }
  useEffect(() => { load(); }, []);

  async function pay(courier) {
    if (!window.confirm(`Pay ${courier.fullName} RM ${courier.pendingBalance.toFixed(2)} now?`)) return;
    setBusyId(courier.deliveryPersonnelId);
    setError('');
    try {
      const res = await payCourier(courier.deliveryPersonnelId);
      setNotice(`Paid ${courier.fullName} RM ${Number(res.amount).toFixed(2)} (${res.deliveryCount} deliveries).`);
      load();
    } catch (err) {
      setError(err.message);
    } finally {
      setBusyId('');
    }
  }

  const fmt = (n) => `RM ${Number(n || 0).toFixed(2)}`;

  return (
    <div className="container py-4">
      <h1 className="mb-1">💸 Courier Payouts</h1>
      <p className="text-muted">
        Couriers earn a flat fee per delivered parcel. Pay out their accrued balance via Stripe.
      </p>

      {notice && (
        <div className="alert alert-success py-2 d-flex justify-content-between align-items-center">
          <span>{notice}</span>
          <button type="button" className="btn-close" onClick={() => setNotice('')}></button>
        </div>
      )}
      {error && <div className="alert alert-danger py-2">{error}</div>}

      {loading ? (
        <p className="text-muted">Loading…</p>
      ) : couriers.length === 0 ? (
        <div className="card card-body text-center text-muted">No active couriers yet.</div>
      ) : (
        <div className="table-responsive">
          <table className="table align-middle">
            <thead>
              <tr>
                <th>Courier</th>
                <th>Payout account</th>
                <th className="text-end">Pending</th>
                <th className="text-end">Deliveries</th>
                <th className="text-end">Action</th>
              </tr>
            </thead>
            <tbody>
              {couriers.map((c) => {
                const ready = c.connected && c.payoutsEnabled;
                const canPay = ready && c.pendingBalance > 0;
                return (
                  <tr key={c.deliveryPersonnelId}>
                    <td>
                      <div className="fw-semibold">{c.fullName}</div>
                      <div className="text-muted small">{c.email}</div>
                    </td>
                    <td className="small">
                      {ready
                        ? <span className="text-success">✓ Connected</span>
                        : c.connected
                          ? <span className="text-warning">Onboarding incomplete</span>
                          : <span className="text-muted">Not connected</span>}
                    </td>
                    <td className="text-end fw-semibold">{fmt(c.pendingBalance)}</td>
                    <td className="text-end">{c.pendingDeliveries}</td>
                    <td className="text-end">
                      <button
                        className="btn btn-primary btn-sm"
                        disabled={!canPay || busyId === c.deliveryPersonnelId}
                        title={!c.connected ? 'Courier must connect Stripe first'
                          : !c.payoutsEnabled ? 'Courier must finish Stripe onboarding'
                          : c.pendingBalance <= 0 ? 'Nothing to pay' : 'Pay this courier'}
                        onClick={() => pay(c)}
                      >
                        {busyId === c.deliveryPersonnelId ? '…' : 'Pay out'}
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

export default AdminCourierPayoutsPage;
