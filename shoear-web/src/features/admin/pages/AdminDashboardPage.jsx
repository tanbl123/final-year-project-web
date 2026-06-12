import { useEffect, useState } from 'react';
import { getPendingSuppliers, approveSupplier, rejectSupplier } from '../adminService';
import ConfirmDialog from '../../../components/ConfirmDialog';

function AdminDashboardPage() {
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');       // transient success message
  const [busyId, setBusyId] = useState('');        // userId currently being actioned
  const [rejecting, setRejecting] = useState(null); // supplier pending reject confirmation

  // load the pending queue on mount
  useEffect(() => {
    let active = true;
    getPendingSuppliers()
      .then((data) => { if (active) setSuppliers(data.suppliers); })
      .catch((err) => { if (active) setError(err.message); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, []);

  // approve / reject share the same shape: call the API, drop the row, notify
  async function act(supplier, action) {
    setBusyId(supplier.userId);
    setError('');
    try {
      if (action === 'approve') await approveSupplier(supplier.userId);
      else await rejectSupplier(supplier.userId);

      setSuppliers((prev) => prev.filter((s) => s.userId !== supplier.userId));
      setNotice(`${supplier.companyName} ${action === 'approve' ? 'approved' : 'rejected'}.`);
    } catch (err) {
      setError(err.message);
    } finally {
      setBusyId('');
    }
  }

  return (
    <div className="container py-4">
      <h1 className="mb-1">🛡️ Supplier Approvals</h1>
      <p className="text-muted">Review supplier accounts awaiting approval.</p>

      {notice && (
        <div className="alert alert-success py-2 d-flex justify-content-between align-items-center">
          <span>{notice}</span>
          <button type="button" className="btn-close" onClick={() => setNotice('')}></button>
        </div>
      )}
      {error && <div className="alert alert-danger py-2">{error}</div>}

      {loading ? (
        <p className="text-muted">Loading…</p>
      ) : suppliers.length === 0 ? (
        <div className="card card-body text-center text-muted">
          🎉 No pending suppliers. You're all caught up.
        </div>
      ) : (
        <div className="table-responsive">
          <table className="table align-middle">
            <thead>
              <tr>
                <th>Company</th>
                <th>Contact</th>
                <th>Address</th>
                <th>Submitted</th>
                <th className="text-end">Actions</th>
              </tr>
            </thead>
            <tbody>
              {suppliers.map((s) => (
                <tr key={s.userId}>
                  <td>
                    <div className="fw-semibold">{s.companyName}</div>
                    <div className="text-muted small">@{s.username}</div>
                  </td>
                  <td>
                    <div>{s.email}</div>
                    <div className="text-muted small">{s.phoneNumber}</div>
                  </td>
                  <td className="text-muted">{s.companyAddress}</td>
                  <td className="text-muted small">{new Date(s.created_at).toLocaleDateString()}</td>
                  <td className="text-end text-nowrap">
                    <button
                      className="btn btn-success btn-sm me-2"
                      disabled={busyId === s.userId}
                      onClick={() => act(s, 'approve')}
                    >
                      {busyId === s.userId ? '…' : 'Approve'}
                    </button>
                    <button
                      className="btn btn-outline-danger btn-sm"
                      disabled={busyId === s.userId}
                      onClick={() => setRejecting(s)}
                    >
                      Reject
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <ConfirmDialog
        isOpen={!!rejecting}
        title="Reject supplier?"
        message={rejecting ? `Reject ${rejecting.companyName}'s registration? They won't be able to log in.` : ''}
        confirmText="Reject"
        confirmColor="danger"
        onCancel={() => setRejecting(null)}
        onConfirm={() => { const s = rejecting; setRejecting(null); act(s, 'reject'); }}
      />
    </div>
  );
}

export default AdminDashboardPage;
