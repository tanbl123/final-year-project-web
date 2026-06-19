import { Link } from 'react-router-dom';

// Bootstrap badge colour for each approval status.
const STATUS_COLORS = {
  Approved: 'success',
  Pending: 'warning',
  Rejected: 'danger',
};

function ProductCard(props) {
  const statusColor = STATUS_COLORS[props.status] || 'secondary';

  return (
    <div className="card h-100 shadow-sm">
      {/* image (or a neutral placeholder when none was uploaded) */}
      <div className="ratio ratio-4x3 bg-light rounded-top overflow-hidden">
        {props.imageUrl ? (
          <img src={props.imageUrl} alt={props.name}
            style={{ objectFit: 'cover' }} className="w-100 h-100" />
        ) : (
          <div className="d-flex align-items-center justify-content-center text-muted fs-1">👟</div>
        )}
      </div>

      <div className="card-body">
        <div className="d-flex justify-content-between align-items-start">
          <h5 className="card-title mb-0">{props.name}</h5>
          {props.status && <span className={`badge text-bg-${statusColor}`}>{props.status}</span>}
        </div>
        <h6 className="card-subtitle mt-1 mb-2 text-muted">{props.brand}</h6>
        <p className="card-text fs-4 fw-bold text-primary mb-1">RM {Number(props.price).toFixed(2)}</p>
        <p className="card-text small text-muted">
          {typeof props.totalStock === 'number' ? `${props.totalStock} in stock` : ''}
        </p>

        <Link to={'/products/' + props.id} className="btn btn-outline-primary btn-sm me-2">
          View
        </Link>
        <Link to={'/products/' + props.id + '/edit'} className="btn btn-outline-secondary btn-sm me-2">
          Edit
        </Link>
        <button className="btn btn-outline-danger btn-sm" onClick={() => props.onDelete(props.id)}>
          Delete
        </button>
      </div>
    </div>
  );
}

export default ProductCard;
