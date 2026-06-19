import { useEffect } from 'react';

// Warn the user with the browser's native "Leave site? Changes you made may not
// be saved" dialog before they REFRESH, CLOSE the tab, or navigate away via the
// URL bar while `when` is true.
//
// Note: this does NOT intercept in-app SPA navigation (clicking React Router
// links) — that requires a data router (useBlocker). It covers the destructive
// browser-level cases, which is what most "unsaved changes" loss comes from.
export function useUnsavedChangesWarning(when) {
  useEffect(() => {
    if (!when) return undefined;
    const handler = (e) => {
      e.preventDefault();
      e.returnValue = '';   // Chrome requires returnValue to be set to show the prompt
      return '';
    };
    window.addEventListener('beforeunload', handler);
    return () => window.removeEventListener('beforeunload', handler);
  }, [when]);
}
