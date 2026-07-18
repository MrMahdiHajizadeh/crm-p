import axios from 'axios';
import { redirect } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';
import { env as publicEnv } from '$env/dynamic/public';

/** @type {import('@sveltejs/kit').ServerLoad} */
export async function load({ url, cookies }) {
  const jwtAccess = cookies.get('jwt_access');
  if (jwtAccess) {
    throw redirect(307, '/org');
  }
  return {};
}

/** @type {import('@sveltejs/kit').Actions} */
export const actions = {
  password: async ({ request, cookies }) => {
    const formData = await request.formData();
    const phone = formData.get('phone');
    const password = formData.get('password');

    if (!phone || !password) {
      return { success: false, error: 'Phone and password are required' };
    }

    try {
      const apiUrl = publicEnv.PUBLIC_DJANGO_API_URL;
      const response = await axios.post(
        `${apiUrl}/api/auth/phone-login/`,
        { phone, password },
        { headers: { 'Content-Type': 'application/json' }, timeout: 15000 }
      );

      const { access_token, refresh_token } = response.data;

      const secure = env.NODE_ENV === 'production';
      cookies.set('jwt_access', access_token, {
        path: '/', httpOnly: true, sameSite: 'lax', secure,
        maxAge: 60 * 60 * 24
      });
      cookies.set('jwt_refresh', refresh_token, {
        path: '/', httpOnly: true, sameSite: 'lax', secure,
        maxAge: 60 * 60 * 24 * 365
      });

      return { success: true, tokens: { access: access_token, refresh: refresh_token } };
    } catch (error) {
      const message = error.response?.data?.error || 'Login failed';
      return { success: false, error: message };
    }
  },

  requestOTP: async ({ request }) => {
    const formData = await request.formData();
    const phone = formData.get('phone');

    if (!phone) {
      return { success: false, error: 'Phone number is required' };
    }

    try {
      const apiUrl = publicEnv.PUBLIC_DJANGO_API_URL;
      await axios.post(
        `${apiUrl}/api/auth/request-phone-code/`,
        { phone },
        { headers: { 'Content-Type': 'application/json' }, timeout: 15000 }
      );
      return { success: true, otpSent: true };
    } catch (error) {
      return { success: false, error: 'Failed to send code' };
    }
  },

  verifyOTP: async ({ request, cookies }) => {
    const formData = await request.formData();
    const phone = formData.get('phone');
    const code = formData.get('code');

    if (!phone || !code) {
      return { success: false, error: 'Phone and code are required' };
    }

    try {
      const apiUrl = publicEnv.PUBLIC_DJANGO_API_URL;
      const response = await axios.post(
        `${apiUrl}/api/auth/verify-phone-code/`,
        { phone, code },
        { headers: { 'Content-Type': 'application/json' }, timeout: 15000 }
      );

      const { access_token, refresh_token } = response.data;

      const secure = env.NODE_ENV === 'production';
      cookies.set('jwt_access', access_token, {
        path: '/', httpOnly: true, sameSite: 'lax', secure,
        maxAge: 60 * 60 * 24
      });
      cookies.set('jwt_refresh', refresh_token, {
        path: '/', httpOnly: true, sameSite: 'lax', secure,
        maxAge: 60 * 60 * 24 * 365
      });

      return { success: true, tokens: { access: access_token, refresh: refresh_token } };
    } catch (error) {
      const message = error.response?.data?.error || 'Invalid or expired code';
      return { success: false, error: message };
    }
  }
};
