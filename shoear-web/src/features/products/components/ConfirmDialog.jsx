function ConfirmDialog(props) {
  // if it's not open, render nothing at all
  if (!props.isOpen) {
    return null;
  }

  return (
    <>
      {/* dark background behind the dialog */}
      <div className="modal-backdrop fade show"></div>

      {/* the dialog box itself */}
      <div className="modal d-block" tabIndex="-1" role="dialog">
        <div className="modal-dialog modal-dialog-centered" role="document">
          <div className="modal-content">

            <div className="modal-header">
              <h5 className="modal-title">{props.title}</h5>
              <button type="button" className="btn-close" onClick={props.onCancel}></button>
            </div>

            <div className="modal-body">
              <p className="mb-0">{props.message}</p>
            </div>

            <div className="modal-footer">
              <button type="button" className="btn btn-secondary" onClick={props.onCancel}>
                {props.cancelText || 'Cancel'}
              </button>
              <button
                type="button"
                className={'btn btn-' + (props.confirmColor || 'primary')}
                onClick={props.onConfirm}
              >
                {props.confirmText || 'Confirm'}
              </button>
            </div>

          </div>
        </div>
      </div>
    </>
  );
}

export default ConfirmDialog;