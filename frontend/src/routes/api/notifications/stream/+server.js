import { env } from '$env/dynamic/public';

const API_BASE_URL = `${env.PUBLIC_DJANGO_API_URL || 'http://backend:8000'}/api`;

/** @type {import('./$types').RequestHandler} */
export async function GET({ cookies, request, locals }) {
  const accessToken = cookies.get('jwt_access');
  if (!accessToken || !locals?.org) {
    return new Response('Unauthorized', { status: 401 });
  }

  try {
    const headers = {
      Authorization: `Bearer ${accessToken}`,
      Accept: 'text/event-stream'
    };
    if (locals?.org?.id) {
      headers['X-Org-Id'] = locals.org.id;
    }

    const upstream = await fetch(`${API_BASE_URL}/notifications/stream/`, {
      method: 'GET',
      headers,
      signal: request.signal
    });

    if (!upstream.ok || !upstream.body) {
      return new Response(': keepalive\n\n', {
        status: 200,
        headers: {
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache, no-transform'
        }
      });
    }

    return new Response(upstream.body, {
      status: 200,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache, no-transform',
        'X-Accel-Buffering': 'no'
      }
    });
  } catch (err) {
    if (err?.name === 'AbortError' || request.signal.aborted) {
      return new Response(null, { status: 204 });
    }
    return new Response(': keepalive\n\n', {
      status: 200,
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache, no-transform'
      }
    });
  }
}
