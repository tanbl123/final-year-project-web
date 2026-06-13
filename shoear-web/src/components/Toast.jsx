import { useEffect } from 'react';

// A small auto-dismissing toast pinned to the top-right. Renders nothing when
// there is no message. `variant` is a Bootstrap colour (success, danger, …).
function Toast({ message, onClose, variant = 'success', duration = 3500 }) {
  useEffect(() => {
    if (!message) return undefined;
    const timer = setTimeout(onClose, duration);
    return () => clearTimeout(timer);
  }, [message, duration, onClose]);

  if (!message) return null;

  return (
    <div className="toast-container position-fixed top-0 end-0 p-3" style={{ zIndex: 1080 }}>
      <div className={`toast show align-items-center text-bg-${variant} border-0`} role="alert" aria-live="assertive">
        <div className="d-flex">
          <div className="toast-body">{message}</div>
          <button type="button" className="btn-close btn-close-white me-2 m-auto"
            aria-label="Close" onClick={onClose}></button>
        </div>
      </div>
    </div>
  );
}

export default Toast;
