/**
 * Follow-ups Page - Server Load
 *
 * Fetches all items with pending follow-up dates from the API,
 * grouped by: overdue, today, tomorrow, this week, later.
 *
 * Django endpoint: GET /api/leads/follow-ups/
 */

import { error, fail } from '@sveltejs/kit';
import { apiRequest } from '$lib/api-helpers.js';

/** @type {import('./$types').PageServerLoad} */
export async function load({ locals, cookies, url }) {
  const org = locals.org;
  if (!org) {
    throw error(401, 'Organization context required');
  }

  const myOnly = url.searchParams.get('my_only') === 'true';

  try {
    const queryPath = '/leads/follow-ups/' + (myOnly ? '?my_only=true' : '');
    const response = await apiRequest(queryPath, {}, { cookies, org });

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
      },
      myOnly
    };
  } catch (err) {
    if (/** @type {any} */ (err)?.status) throw err;
    console.error('Failed to load follow-ups:', err);
    throw error(500, 'Failed to load follow-ups');
  }
}

/** @type {import('./$types').Actions} */
export const actions = {
  createInteraction: async ({ request, locals, cookies }) => {
    const org = locals.org;
    if (!org) {
      return fail(401, { error: 'Organization context required' });
    }

    try {
      const form = await request.formData();

      const entityType = form.get('entity_type')?.toString() || 'Lead';
      const entityId = form.get('entity_id')?.toString() || '';
      const interactionType = form.get('interaction_type')?.toString() || 'call';
      const interactionDate = form.get('interaction_date')?.toString() || new Date().toISOString();
      const durationMinutes = form.get('duration_minutes')?.toString() || null;
      const subject = form.get('subject')?.toString().trim() || '';
      const description = form.get('description')?.toString().trim() || '';
      const result = form.get('result')?.toString() || null;
      const followUpDate = form.get('follow_up_date')?.toString() || null;

      if (!subject && !description) {
        return fail(400, { error: 'validation_required' });
      }

      const completedId = form.get('completed_interaction_id')?.toString() || null;

      const payload = {
        entity_type: entityType,
        entity_id: entityId,
        interaction_type: interactionType,
        interaction_date: interactionDate,
        duration_minutes: durationMinutes ? parseInt(durationMinutes) : null,
        subject,
        description,
        result: result || null,
        follow_up_date: followUpDate || null,
      };

      await apiRequest(
        '/leads/interactions/',
        { method: 'POST', body: payload },
        { cookies, org }
      );

      // Clear follow_up_date on the old interaction so it disappears from the list
      if (completedId) {
        try {
          await apiRequest(
            `/leads/interactions/${completedId}/`,
            { method: 'PATCH', body: { follow_up_date: null } },
            { cookies, org }
          );
        } catch (e) {
          // Non-critical — the new interaction was still created
          console.warn('Failed to clear old follow-up:', e);
        }
      }

      return { success: true };
    } catch (err) {
      console.error('Error creating interaction:', err);
      return fail(500, {
        error: /** @type {any} */ (err)?.message || 'Failed to create interaction'
      });
    }
  }
};
