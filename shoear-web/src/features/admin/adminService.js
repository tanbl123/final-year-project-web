import { apiGet, apiPost, getToken } from '../../api/client';

// Suppliers awaiting approval.
export function getPendingSuppliers() {
  return apiGet('/admin/suppliers/pending', getToken());
}

// Approve a pending supplier (status → Active, so they can log in).
export function approveSupplier(userId) {
  return apiPost(`/admin/suppliers/${userId}/approve`, {}, getToken());
}

// Reject a pending supplier (status → Rejected).
export function rejectSupplier(userId) {
  return apiPost(`/admin/suppliers/${userId}/reject`, {}, getToken());
}
