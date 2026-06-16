import { apiGet, apiPost, apiPut, apiPatch, apiDelete, getToken } from '../../api/client';

// Suppliers awaiting approval.
export function getPendingSuppliers() {
  return apiGet('/admin/suppliers/pending', getToken());
}

// Approve a pending supplier (status → Active, so they can log in).
export function approveSupplier(userId) {
  return apiPost(`/admin/suppliers/${userId}/approve`, {}, getToken());
}

// Reject a pending supplier. reason is required and shown to the supplier;
// terminal=true bans them permanently, otherwise they may fix it and resubmit.
export function rejectSupplier(userId, { reason, terminal = false } = {}) {
  return apiPost(`/admin/suppliers/${userId}/reject`, { reason, terminal }, getToken());
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

// ── supplier business-detail change requests (re-approval queue) ──────
export function getSupplierChangeRequests() {
  return apiGet('/admin/supplier-changes', getToken());
}

export function approveChangeRequest(requestId) {
  return apiPost(`/admin/supplier-changes/${requestId}/approve`, {}, getToken());
}

export function rejectChangeRequest(requestId, reason) {
  return apiPost(`/admin/supplier-changes/${requestId}/reject`, { reason }, getToken());
}

// ── category management ──────────────────────────────────────────────
// List categories with how many products use each.
export function getCategoriesAdmin() {
  return apiGet('/admin/categories', getToken());
}

export function createCategory(name) {
  return apiPost('/admin/categories', { name }, getToken());
}

export function renameCategory(id, name) {
  return apiPut(`/admin/categories/${id}`, { name }, getToken());
}

export function deleteCategory(id) {
  return apiDelete(`/admin/categories/${id}`, getToken());
}

// ── user management ──────────────────────────────────────────────────
// filters: { role, status, search } — any can be omitted/empty.
export function getUsers(filters = {}) {
  const qs = new URLSearchParams();
  if (filters.role) qs.set('role', filters.role);
  if (filters.status) qs.set('status', filters.status);
  if (filters.search) qs.set('search', filters.search);
  const suffix = qs.toString() ? `?${qs.toString()}` : '';
  return apiGet(`/admin/users${suffix}`, getToken());
}

export function getUser(userId) {
  return apiGet(`/admin/users/${userId}`, getToken());
}

export function setUserStatus(userId, status) {
  return apiPatch(`/admin/users/${userId}/status`, { status }, getToken());
}

// ── reports ──────────────────────────────────────────────────────────
// Platform commission across all suppliers (paid orders only).
export function getCommissionReport() {
  return apiGet('/admin/reports/commission', getToken());
}
