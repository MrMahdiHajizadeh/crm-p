/**
 * Follow-ups Page - Server Load
 *
 * Fetches all items with pending follow-up dates from the API,
 * grouped by: overdue, today, tomorrow, this week, later.
 *
 * Django endpoint: GET /api/leads/follow-ups/
 */

import { error } from '@sveltejs/kit';
import { apiRequest } from '$lib/api-helpers.js';

/** @type {import('./$types').PageServerLoad} */
export async function load({ locals, cookies }) {
  const org = locals.org;
  if (!org) {
    throw error(401, 'Organization context required');
  }

  try {
    const response = await apiRequest('/leads/follow-ups/', {}, { cookies, org });

    if (response?.error) {
      throw error(500, response.errors || 'Failed to load follow-ups');
    }

    return {
      groups: {
        overdue: response.overdue || [],
        today: response.today || [],
        tomorrow: response.tomorrow || [],
        thisWeek: response.this_week || [],
        later: response.later || [],
      }
    };
  } catch (err) {
    if (/** @type {any} */ (err)?.status) throw err;
    console.error('Failed to load follow-ups:', err);
    throw error(500, 'Failed to load follow-ups');
  }
}
