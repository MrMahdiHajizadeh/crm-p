import { error, fail } from '@sveltejs/kit';
import { apiRequest } from '$lib/api-helpers.js';

/** @type {import('./$types').PageServerLoad} */
export async function load({ cookies, locals }) {
  const profile = locals.profile;
  const isAdmin = profile?.role === 'ADMIN' || profile?.is_organization_admin || profile?.is_admin;
  if (!isAdmin) {
    throw error(403, 'Only admins can access AI settings');
  }

  try {
    const response = await apiRequest('/ai/settings/', {}, { cookies });
    return {
      aiSettings: response
    };
  } catch (err) {
    console.error('Failed to load AI settings:', err);
    return {
      aiSettings: {
        api_url: 'https://api.openai.com/v1',
        model_name: 'gpt-4o-mini',
        proxy_url: '',
        is_active: true
      }
    };
  }
}

/** @type {import('./$types').Actions} */
export const actions = {
  update: async ({ request, cookies, locals }) => {
    const profile = locals.profile;
    const isAdmin = profile?.role === 'ADMIN' || profile?.is_organization_admin || profile?.is_admin;
    if (!isAdmin) {
      return fail(403, { error: 'Only admins can update AI settings' });
    }
    const formData = await request.formData();

    const data = {
      api_key: formData.get('api_key') || '',
      api_url: formData.get('api_url') || 'https://api.openai.com/v1',
      model_name: formData.get('model_name') || 'gpt-4o-mini',
      proxy_url: formData.get('proxy_url') || '',
      is_active: formData.get('is_active') === 'on'
    };

    try {
      const response = await apiRequest(
        '/ai/settings/',
        { method: 'PATCH', body: data },
        { cookies }
      );
      return { success: true, aiSettings: response };
    } catch (err) {
      console.error('Failed to update AI settings:', err);
      const message = err?.message || 'خطا در بروزرسانی تنظیمات هوش مصنوعی';
      return fail(400, { error: message });
    }
  }
};
