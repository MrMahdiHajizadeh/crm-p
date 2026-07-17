import { writable } from 'svelte/store';

/**
 * @typedef {Object} OrgSettings
 * @property {string} default_currency - Default currency code (e.g., 'TOM', 'USD')
 * @property {string} currency_symbol - Currency symbol (e.g., '$', '€')
 * @property {string|null} default_country - Default country code or null
 * @property {boolean} opportunities_enabled - Show Opportunities section in sidebar
 * @property {boolean} invoices_enabled - Show Invoices section in sidebar
 */

/** @type {import('svelte/store').Writable<OrgSettings>} */
export const orgSettings = writable({
  default_currency: 'TOM',
  currency_symbol: 'تومان',
  default_country: 'IR',
  opportunities_enabled: false,
  invoices_enabled: false
});

/**
 * Initialize org settings from JWT or API response
 * @param {Partial<OrgSettings>} settings
 */
export function initOrgSettings(settings) {
  orgSettings.set({
    default_currency: settings.default_currency || 'TOM',
    currency_symbol: settings.currency_symbol || 'تومان',
    default_country: settings.default_country || 'IR',
    opportunities_enabled: settings.opportunities_enabled ?? false,
    invoices_enabled: settings.invoices_enabled ?? false
  });
}
