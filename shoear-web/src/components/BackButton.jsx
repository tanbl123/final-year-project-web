import { useNavigate, Link } from 'react-router-dom';

// A standard, left-aligned back control for detail/sub pages — a subtle outline
// button with a chevron, like real e-commerce sites (not a centered hyperlink).
// Pass `to` for a fixed destination, or omit it to go back in history.
function BackButton({ to, label = 'Back', className = '' }) {
  const navigate = useNavigate();
  const cls = `btn btn-outline-secondary btn-sm d-inline-flex align-items-center gap-1 ${className}`;
  const inner = (
    <>
      <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">
        <path d="M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z" />
      </svg>
      {label}
    </>
  );
  return (
    <div className="text-start mb-3">
      {to
        ? <Link to={to} className={cls}>{inner}</Link>
        : <button type="button" className={cls} onClick={() => navigate(-1)}>{inner}</button>}
    </div>
  );
}

export default BackButton;
