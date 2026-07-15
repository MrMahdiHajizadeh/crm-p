import { json } from '@sveltejs/kit';
import { env } from '$env/dynamic/public';

const API_BASE_URL = `${env.PUBLIC_DJANGO_API_URL}/api`;

function extractError(data) {
  if (!data) return 'Unknown error';
  if (data.errors && typeof data.errors === 'object' && !Array.isArray(data.errors)) {
    const firstKey = Object.keys(data.errors)[0];
    const val = data.errors[firstKey];
    if (Array.isArray(val)) return val[0] || 'Validation error';
    if (typeof val === 'string') return val;
    return String(val);
  }
  if (typeof data.error === 'string') return data.error;
  if (Array.isArray(data.errors)) return data.errors[0] || 'Validation error';
  return 'Failed to process request';
}

export async function POST({ request, locals, cookies }) {
  const org = locals.org;
  const accessToken = cookies.get('jwt_access');

  if (!org || !accessToken) {
    return json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const body = await request.json();
    const { name, description, users } = body;

    if (!name?.trim()) {
      return json({ error: 'Team name is required' }, { status: 400 });
    }

    const response = await fetch(`${API_BASE_URL}/teams/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
        org: org.id
      },
      body: JSON.stringify({
        name: name.trim(),
        description: description?.trim() || '',
        assign_users: true,
        users: users || []
      })
    });

    const data = await response.json();

    if (!response.ok) {
      const errMsg = extractError(data);
      return json({ error: errMsg }, { status: response.status });
    }

    return json({ success: true });
  } catch (err) {
    console.error('[teams/POST] Error:', err);
    return json({ error: err.message || 'Failed to create team' }, { status: 500 });
  }
}

export async function PUT({ request, locals, cookies }) {
  const org = locals.org;
  const accessToken = cookies.get('jwt_access');

  if (!org || !accessToken) {
    return json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const body = await request.json();
    const { team_id, name, description, users } = body;

    if (!team_id) {
      return json({ error: 'Team ID is required' }, { status: 400 });
    }

    if (!name?.trim()) {
      return json({ error: 'Team name is required' }, { status: 400 });
    }

    const response = await fetch(`${API_BASE_URL}/teams/${team_id}/`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
        org: org.id
      },
      body: JSON.stringify({
        name: name.trim(),
        description: description?.trim() || '',
        assign_users: users || []
      })
    });

    const data = await response.json();

    if (!response.ok) {
      const errMsg = extractError(data);
      return json({ error: errMsg }, { status: response.status });
    }

    return json({ success: true });
  } catch (err) {
    console.error('[teams/PUT] Error:', err);
    return json({ error: err.message || 'Failed to update team' }, { status: 500 });
  }
}
