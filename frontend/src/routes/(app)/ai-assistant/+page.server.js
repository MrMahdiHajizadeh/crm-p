import { error } from '@sveltejs/kit';
import { apiRequest } from '$lib/api-helpers.js';

/** @type {import('./$types').PageServerLoad} */
export async function load({ cookies }) {
  try {
    const [sessions, aiSettings] = await Promise.all([
      apiRequest('/ai/sessions/', {}, { cookies }).catch(() => []),
      apiRequest('/ai/settings/', {}, { cookies }).catch(() => ({}))
    ]);

    return {
      sessions: Array.isArray(sessions) ? sessions : [],
      aiSettings: aiSettings || {}
    };
  } catch (err) {
    console.error('Failed to load AI Assistant sessions:', err);
    return {
      sessions: [],
      aiSettings: {}
    };
  }
}
