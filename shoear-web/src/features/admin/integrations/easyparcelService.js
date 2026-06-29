import { apiGet, apiPost, getToken } from '../../../api/client';

// Is EasyParcel configured (app credentials present) + connected (admin has
// completed the one-time OAuth consent)? Returns
// { configured, connected, live, connectedAt, accountId, refreshExpiresAt, redirectUri }.
export function getEasyParcelStatus() {
  return apiGet('/easyparcel/status', getToken());
}

// Begin the OAuth connect: the backend stashes a one-time state and returns the
// EasyParcel consent URL. The caller then redirects the browser there.
export function getEasyParcelAuthorizeUrl() {
  return apiGet('/easyparcel/connect', getToken());
}

// Clear the stored tokens (disconnect the account).
export function disconnectEasyParcel() {
  return apiPost('/easyparcel/disconnect', {}, getToken());
}
