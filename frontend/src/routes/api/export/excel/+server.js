import { getApiBaseUrl } from '$lib/api-helpers.js';

/** @type {import('./$types').RequestHandler} */
export async function GET({ url, cookies, locals }) {
  const type = url.searchParams.get('type') || 'leads';
  const token = cookies.get('jwt_access');
  const orgId = locals.org?.id || cookies.get('org_id');

  const baseUrl = getApiBaseUrl();
  const backendUrl = `${baseUrl}/export/excel/?type=${type}`;

  /** @type {Record<string, string>} */
  const headers = {};
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  if (orgId) {
    headers['X-Organization'] = orgId;
  }

  try {
    const res = await fetch(backendUrl, { headers });

    if (!res.ok) {
      return new Response('Export failed', { status: res.status });
    }

    const arrayBuffer = await res.arrayBuffer();
    return new Response(arrayBuffer, {
      status: 200,
      headers: {
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': `attachment; filename="crm_export_${type}.xlsx"`
      }
    });
  } catch (err) {
    console.error('SvelteKit Excel proxy error:', err);
    return new Response('Internal Server Error', { status: 500 });
  }
}
