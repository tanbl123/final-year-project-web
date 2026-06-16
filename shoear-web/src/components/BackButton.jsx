import { useNavigate, Link } from 'react-router-dom';

// A standard, left-aligned back control for detail/sub pages — a small outline
// button showing just a ← arrow (real e-commerce sites keep it minimal). Pass
// `label` to also show text; pass `to` for a fixed destination, or omit it to
// go back in history.
function BackButton({ to, label, className = '' }) {
  const navigate = useNavigate();
  const cls = `btn btn-outline-secondary btn-sm d-inline-flex align-items-center gap-1 ${className}`;
  const title = label || 'Go back';
  const inner = (
    <>
      <svg width="18" height="18" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">
        <path d="M15 8a.5.5 0 0 0-.5-.5H2.707l3.147-3.146a.5.5 0 1 0-.708-.708l-4 4a.5.5 0 0 0 0 .708l4 4a.5.5 0 0 0 .708-.708L2.707 8.5H14.5A.5.5 0 0 0 15 8z" />
      </svg>
      {label && <span>{label}</span>}
    </>
  );
  return (
    <div className="text-start mb-3">
      {to
        ? <Link to={to} className={cls} aria-label={title} title={title}>{inner}</Link>
        : <button type="button" className={cls} aria-label={title} title={title} onClick={() => navigate(-1)}>{inner}</button>}
    </div>
  );
}

export default BackButton;
