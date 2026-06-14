import { useMemo, useState } from 'react';

// Client-side pagination over an in-memory list.
// Returns the current page slice plus the controls a list page needs.
export function usePagination(items, pageSize = 10) {
  const [rawPage, setPage] = useState(1);
  const totalPages = Math.max(1, Math.ceil(items.length / pageSize));

  // clamp during render so a shrinking list (filter/delete) never leaves us
  // stranded on an out-of-range page — no effect, no cascading re-render
  const page = Math.min(rawPage, totalPages);

  const pageItems = useMemo(
    () => items.slice((page - 1) * pageSize, page * pageSize),
    [items, page, pageSize]);

  return { page, setPage, totalPages, pageItems };
}
