import { apiGet, apiPost, getToken } from '../../api/client';

// Current Stripe Connect payout status for the signed-in supplier.
// Resolves with { connected, payoutsEnabled, configured, detailsSubmitted? }.
export function getPayoutStatus() {
  return apiGet('/supplier/stripe/status', getToken());
}

// Start (or resume) Stripe-hosted onboarding. Resolves with { url } to redirect to.
export function startStripeOnboarding() {
  return apiPost('/supplier/stripe/onboard', {}, getToken());
}
