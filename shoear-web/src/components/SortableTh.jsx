// A clickable table header that drives a useTableSort() instance.
// Pass the hook's return value as `sort`.
function SortableTh({ label, columnKey, sort, className = '', style }) {
  const { sortKey, sortDir, toggleSort } = sort;
  const arrow = sortKey === columnKey ? (sortDir === 'asc' ? ' ▲' : ' ▼') : ' ⇅';
  return (
    <th role="button" className={className}
      onClick={() => toggleSort(columnKey)}
      style={{ cursor: 'pointer', userSelect: 'none', whiteSpace: 'nowrap', ...style }}>
      {label}<span className="text-muted small">{arrow}</span>
    </th>
  );
}

export default SortableTh;
