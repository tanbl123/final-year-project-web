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

// Products awaiting approval.
export function getPendingProducts() {
  return apiGet('/admin/products/pending', getToken());
}

// Approve a pending product (status → Approved, so it's visible on the platform).
export function approveProduct(productId) {
  return apiPost(`/admin/products/${productId}/approve`, {}, getToken());
}

// Reject a pending product (status → Rejected).
export function rejectProduct(productId) {
  return apiPost(`/admin/products/${productId}/reject`, {}, getToken());
}
