// A text input with an Instagram-style clear (✕) button on the right that
// appears only when there's text and empties the field in one click — so users
// don't have to hold backspace. Pass the usual input props (name, type, value,
// onChange, onBlur, placeholder, className) plus an onClear handler.
function ClearableInput({ value, onClear, className = '', style, ...props }) {
  return (
    <div className="position-relative">
      <input
        {...props}
        value={value}
        className={`form-control ${className}`}
        // leave room for the button + drop Bootstrap's validation icon so the
        // two don't overlap (the red border + message still convey errors)
        style={{ paddingRight: '2.75rem', backgroundImage: 'none', ...style }}
      />
      {value && (
        <button
          type="button"
          tabIndex={-1}
          aria-label="Clear"
          onMouseDown={(e) => e.preventDefault()}   // don't steal focus on click
          onClick={onClear}
          className="btn position-absolute top-50 end-0 translate-middle-y p-1 me-1 d-flex align-items-center text-secondary border-0"
          style={{ lineHeight: 1, background: 'none' }}
        >
          <svg width="20" height="20" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">
            <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708z" />
          </svg>
        </button>
      )}
    </div>
  );
}

export default ClearableInput;
