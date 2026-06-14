// Numbered pager for client-side lists. Renders nothing for a single page.
//   page, totalPages — usually straight from usePagination()
//   onChange         — receives the new page number
//   summary          — optional caption under the pager (e.g. "Page 1 of 3 · 24 users")
function Pagination({ page, totalPages, onChange, summary }) {
  if (totalPages <= 1) return null;
  return (
    <nav className="d-flex flex-column align-items-center gap-2">
      <ul className="pagination mb-0">
        <li className={'page-item' + (page === 1 ? ' disabled' : '')}>
          <button className="page-link" onClick={() => onChange(Math.max(1, page - 1))}>Prev</button>
        </li>
        {Array.from({ length: totalPages }, (_, i) => i + 1).map((n) => (
          <li key={n} className={'page-item' + (n === page ? ' active' : '')}>
            <button className="page-link" onClick={() => onChange(n)}>{n}</button>
          </li>
        ))}
        <li className={'page-item' + (page === totalPages ? ' disabled' : '')}>
          <button className="page-link" onClick={() => onChange(Math.min(totalPages, page + 1))}>Next</button>
        </li>
      </ul>
      {summary && <span className="text-muted small">{summary}</span>}
    </nav>
  );
}

export default Pagination;
