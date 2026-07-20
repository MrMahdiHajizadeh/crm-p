import { error, fail, redirect } from '@sveltejs/kit';
import { apiRequest } from '$lib/api-helpers.js';

/** @type {import('./$types').PageServerLoad} */
export async function load({ params, locals, cookies }) {
  if (!locals.org) throw error(401, 'Organization context required');
  // Redirect to the main leads page with the view drawer open
  throw redirect(303, '/leads?view=' + params.id);
}

/** @type {import('./$types').Actions} */
export const actions = {
  default: async ({ request, params, locals, cookies }) => {
    const form = await request.formData();
    const get = (k) => form.get(k)?.toString().trim() || '';
    const title = get('title');
    if (!title) return fail(400, { error: 'Title is required' });
    const body = { title, description: get('description') || '', org: locals.org.id };
    const map = {
      salutation: 'salutation', firstName: 'first_name', lastName: 'last_name',
      email: 'email', phone: 'phone', jobTitle: 'job_title',
      website: 'website', linkedinUrl: 'linkedin_url', industry: 'industry',
      company: 'company_name', source: 'source', status: 'status', rating: 'rating',
      currency: 'currency', addressLine: 'address_line', city: 'city',
      state: 'state', postcode: 'postcode', country: 'country'
    };
    for (const [fk, ak] of Object.entries(map)) { const v = get(fk); if (v) body[ak] = v; }
    const a = get('opportunityAmount');
    if (a) body.opportunity_amount = parseFloat(a);
    const p = get('probability');
    if (p) body.probability = parseInt(p, 10);
    for (const k of ['closeDate', 'lastContacted', 'nextFollowUp']) {
      const v = get(k);
      if (v) body[k.replace(/[A-Z]/g, (c) => '_' + c.toLowerCase())] = v;
    }
    try {
      await apiRequest('/leads/' + params.id + '/', { method: 'PATCH', body }, { cookies, org: locals.org });
    } catch (err) {
      return fail(err?.status || 500, { error: err?.message || 'Failed to update lead' });
    }
    throw redirect(303, '/leads/' + params.id);
  }
};
