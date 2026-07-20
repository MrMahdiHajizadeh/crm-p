import { apiRequest } from '$lib/api-helpers.js';

/** @type {import('./$types').LayoutServerLoad} */
export async function load({ locals, cookies }) {
  // Try to fetch fresh org settings from API (in case JWT is stale)
  let orgSettings = locals.org_settings || {
    default_currency: 'TOM',
    currency_symbol: 'تومان',
    default_country: 'IR',
    opportunities_enabled: false,
    invoices_enabled: false
  };

  try {
    const fresh = await apiRequest('/org/settings/', {}, { cookies });
    if (fresh && fresh.default_currency) {
      orgSettings = {
        default_currency: fresh.default_currency || 'TOM',
        currency_symbol: fresh.currency_symbol || 'تومان',
        default_country: fresh.default_country || 'IR',
        opportunities_enabled: fresh.opportunities_enabled ?? false,
        invoices_enabled: fresh.invoices_enabled ?? false
      };
    }
  } catch {
    // Use JWT fallback if API fetch fails
  }

  // Get JWT access token from cookies for client-side API sync
  const jwtAccess = cookies.get('jwt_access') || null;

  return {
    user: locals.user,
    org_id: locals.org?.id || null,
    org_name: locals.org_name || 'BottleCRM',
    org_settings: orgSettings,
    jwt_access: jwtAccess
  };
}

export const ssr = true;
