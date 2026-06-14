import { useEffect, useState } from 'react';
import { getCommissionReport } from '../adminService';

const rm = (n) => 'RM ' + Number(n || 0).toLocaleString('en-MY', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

function ReportsPage() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    let active = true;
    getCommissionReport()
      .then((d) => { if (active) setData(d); })
      .catch((err) => { if (active) setError(err.message); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, []);

  return (
    <div className="container py-4 text-start">
      <h1 className="mb-1">💰 Commission Report</h1>
      <p className="text-muted">Platform commission earned across all suppliers (paid orders).</p>

      {error && <div className="alert alert-danger py-2">{error}</div>}

      {loading ? (
        <p className="text-muted">Loading…</p>
      ) : !data ? null : data.summary.suppliers === 0 ? (
        <div className="card card-body text-center text-muted">No sales recorded yet.</div>
      ) : (
        <>
          <div className="row g-3 mb-4">
            <div className="col-6 col-lg-4">
              <div className="card h-100"><div className="card-body">
                <div className="text-muted small text-uppercase">Gross sales</div>
                <div className="fs-4 fw-semibold">{rm(data.summary.grossSales)}</div>
              </div></div>
            </div>
            <div className="col-6 col-lg-4">
              <div className="card h-100"><div className="card-body">
                <div className="text-muted small text-uppercase">Commission ({data.commissionRate}%)</div>
                <div className="fs-4 fw-semibold text-success">{rm(data.summary.totalCommission)}</div>
              </div></div>
            </div>
            <div className="col-6 col-lg-4">
              <div className="card h-100"><div className="card-body">
                <div className="text-muted small text-uppercase">Suppliers with sales</div>
                <div className="fs-4 fw-semibold">{data.summary.suppliers}</div>
              </div></div>
            </div>
          </div>

          <h5 className="mb-3">By supplier</h5>
          <div className="table-responsive">
            <table className="table align-middle">
              <thead>
                <tr>
                  <th>Supplier</th>
                  <th className="text-end" style={{ width: 110 }}>Units</th>
                  <th className="text-end" style={{ width: 160 }}>Gross sales</th>
                  <th className="text-end" style={{ width: 180 }}>Commission ({data.commissionRate}%)</th>
                </tr>
              </thead>
              <tbody>
                {data.bySupplier.map((s) => (
                  <tr key={s.supplierId}>
                    <td className="fw-semibold">{s.companyName}</td>
                    <td className="text-end">{s.units}</td>
                    <td className="text-end">{rm(s.gross)}</td>
                    <td className="text-end text-success">{rm(s.commission)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="fw-semibold border-top">
                  <td>Total</td>
                  <td className="text-end">—</td>
                  <td className="text-end">{rm(data.summary.grossSales)}</td>
                  <td className="text-end text-success">{rm(data.summary.totalCommission)}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </>
      )}
    </div>
  );
}

export default ReportsPage;
