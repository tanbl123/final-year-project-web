function ProductCard(props) {
  return (
    <div className="card h-100 shadow-sm">
      <div className="card-body">
        <h5 className="card-title">{props.name}</h5>
        <h6 className="card-subtitle mb-2 text-muted">{props.brand}</h6>
        <p className="card-text fs-4 fw-bold text-primary">RM {props.price}</p>
        <button className="btn btn-outline-primary btn-sm">View</button>
      </div>
    </div>
  );
}

export default ProductCard;