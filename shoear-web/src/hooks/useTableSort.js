import { useMemo, useState } from 'react';

// Client-side sorting for a table.
//   items      — the array to sort
//   initialKey — column key to sort by first
//   initialDir — 'asc' | 'desc'
//   getValue   — (item, key) => comparable value (defaults to item[key]);
//                numbers compare numerically, everything else via localeCompare.
//
// Returns { sorted, sortKey, sortDir, toggleSort } — pass the whole object
// to <SortableTh sort={...} /> for the clickable headers.
export function useTableSort(items, { initialKey, initialDir = 'asc', getValue } = {}) {
  const [sortKey, setSortKey] = useState(initialKey);
  const [sortDir, setSortDir] = useState(initialDir);

  // click a column to sort by it; click again to flip the direction
  function toggleSort(key) {
    if (sortKey === key) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortKey(key);
      setSortDir('asc');
    }
  }

  const pick = getValue || ((item, key) => item[key]);

  const sorted = useMemo(() => {
    const list = [...items];
    list.sort((a, b) => {
      const va = pick(a, sortKey);
      const vb = pick(b, sortKey);
      let cmp;
      if (typeof va === 'number' && typeof vb === 'number') cmp = va - vb;
      else cmp = String(va ?? '').localeCompare(String(vb ?? ''));
      return sortDir === 'asc' ? cmp : -cmp;
    });
    return list;
    // pick is rebuilt each render but its logic is stable, so it's left out of deps
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [items, sortKey, sortDir]);

  return { sorted, sortKey, sortDir, toggleSort };
}
