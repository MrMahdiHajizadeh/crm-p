/**
 * Lead Detail Page - Server Load
 *
 * Django endpoint: GET /api/leads/<id>/
 * Response shape: { lead_obj, attachments, comments, users_mention, assigned_data,
 *                   users, users_excluding_team, source, status, teams, countries }
 * (see backend/leads/views/lead_views.py LeadDetailView.get_context_data)
 */

import { error, fail } from '@sveltejs/kit';
import { apiRequest } from '$lib/api-helpers.js';

/** @type {import('./$types').PageServerLoad} */
export async function load({ params, locals, cookies }) {
  const org = locals.org;
  if (!org) {
    throw error(401, 'Organization context required');
  }

  try {
    const response = await apiRequest(`/leads/${params.id}/`, {}, { cookies, org });

    if (response?.error) {
      throw error(404, response.errors || 'Lead not found');
    }

    // Django LeadDetailView returns the lead under `lead_obj` (see backend/leads/views/lead_views.py).
    const lead = response.lead_obj || response.lead || response;

    return {
      lead,
      comments: response.comments || [],
      attachments: response.attachments || [],
      interactions: response.interactions || [],
      tags: response.tags || lead?.tags || [],
      users: response.users || [],
      commentPermission: response.comment_permission || false,
      customFieldDefinitions: response.custom_field_definitions || [],
      customFieldValues: lead?.custom_fields || {}
    };
  } catch (err) {
    if (/** @type {any} */ (err)?.status) throw err;
    console.error('Failed to load lead detail:', err);
    throw error(500, 'Failed to load lead');
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

      return { success: true };
    } catch (err) {
      console.error('Error creating interaction:', err);
      return fail(500, {
        error: /** @type {any} */ (err)?.message || 'Failed to create interaction'
      });
    }
  },

  updateCustomFields: async ({ request, params, locals, cookies }) => {
    const form = await request.formData();
    const raw = form.get('custom_fields')?.toString() || '{}';
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch {
      return fail(400, { error: 'Malformed custom_fields payload' });
    }
    try {
      await apiRequest(
        `/leads/${params.id}/`,
        { method: 'PATCH', body: { custom_fields: parsed } },
        { cookies, org: locals.org }
      );
      return { success: true };
    } catch (err) {
      console.error('Update lead custom fields error:', err);
      return fail(400, {
        error: /** @type {any} */ (err)?.message || 'Failed to save custom fields'
      });
    }
  }
};
