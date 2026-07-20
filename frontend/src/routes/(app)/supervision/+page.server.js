/**
 * Supervision Page - Server Load
 *
 * Fetches all user activities with filtering options.
 * All org members can view activities (RLS removed for team-wide visibility).
 *
 * Django endpoint: GET /api/activities/
 */

import { error } from '@sveltejs/kit';
import { apiRequest } from '$lib/api-helpers.js';

/** @type {import('./$types').PageServerLoad} */
export async function load({ locals, cookies, url }) {
  const org = locals.org;
  if (!org) {
    throw error(401, 'Organization context required');
  }

  // Build query params from URL
  const params = new URLSearchParams();
  const entityType = url.searchParams.get('entity_type');
  const action = url.searchParams.get('action');
  const userId = url.searchParams.get('user_id');
  const dateFrom = url.searchParams.get('date_from');
  const dateTo = url.searchParams.get('date_to');
  const limit = url.searchParams.get('limit') || '50';
  const offset = url.searchParams.get('offset') || '0';

  if (entityType) params.set('entity_type', entityType);
  if (action) params.set('action', action);
  if (userId) params.set('user_id', userId);
  if (dateFrom) params.set('date_from', dateFrom);
  if (dateTo) params.set('date_to', dateTo);
  params.set('limit', limit);
  params.set('offset', offset);

  const queryString = params.toString();
  const endpoint = `/activities/${queryString ? '?' + queryString : ''}`;

  try {
    const response = await apiRequest(endpoint, {}, { cookies, org });

    if (response?.error) {
      throw error(500, response.errors || 'Failed to load activities');
    }

    return {
      activities: response.activities || [],
      totalCount: response.total_count || 0,
      offset: response.offset || 0,
      limit: response.limit || 50,
    };
  } catch (err) {
    if (/** @type {any} */ (err)?.status) throw err;
    console.error('Failed to load activities:', err);
    throw error(500, 'Failed to load activities');
  }
}
