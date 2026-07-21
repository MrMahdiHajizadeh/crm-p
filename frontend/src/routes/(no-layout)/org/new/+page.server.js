/**
 * Organization Create Page - API Version
 *
 * Migrated from Prisma to Django REST API
 * Django endpoint: POST /api/org/
 *
 * To activate:
 *   mv +page.server.js +page.server.prisma.js
 *   mv +page.server.api.js +page.server.js
 */

import { env } from '$env/dynamic/private';
import { env as publicEnv } from '$env/dynamic/public';
import { redirect, fail } from '@sveltejs/kit';
import axios from 'axios';

/** @type {import('./$types').PageServerLoad} */
export async function load({ cookies }) {
  // Single-org system: if an organization already exists, redirect to org list
  try {
    const jwtAccess = cookies.get('jwt_access');
    if (jwtAccess) {
      const apiUrl = publicEnv.PUBLIC_DJANGO_API_URL;
      const response = await axios.get(`${apiUrl}/api/org/`, {
        headers: { Authorization: `Bearer ${jwtAccess}` }
      });
      const orgs = response.data?.profile_org_list || [];
      // If the user is already a member of any org, redirect back to org list
      if (orgs.length > 0) {
        throw redirect(302, '/org');
      }
    }
  } catch (err) {
    // Re-throw redirects so SvelteKit handles them properly
    if (err?.status === 302 || err?.status === 303) throw err;
    // Log but don't block — backend will handle duplicate/pre-existing cases
    console.error('Org pre-check failed:', err?.message);
  }
}

/** @type {import('./$types').Actions} */
export const actions = {
  default: async ({ request, cookies }) => {
    // Auth: check JWT access cookie (primary auth method for this app)
    const jwtAccess = cookies.get('jwt_access');
    if (!jwtAccess) {
      return fail(401, {
        error: { name: 'You must be logged in to create an organization' },
      });
    }

    // Get the submitted form data
    const formData = await request.formData();
    const orgName = formData.get('org_name')?.toString();

    if (!orgName || orgName.trim().length === 0) {
      return fail(400, {
        error: { name: 'Organization name is required' },
      });
    }

    try {
      const apiUrl = publicEnv.PUBLIC_DJANGO_API_URL;

      // Create organization and profile via Django API
      // Django's OrgProfileCreateView creates both org and profile
      const response = await axios.post(
        `${apiUrl}/api/org/`,
        { name: orgName.trim() },
        {
          headers: {
            Authorization: `Bearer ${jwtAccess}`,
            'Content-Type': 'application/json',
          },
        }
      ).catch((err) => {
        // Handle 403 from backend (single-org restriction)
        if (err.response?.status === 403) {
          return {
            data: null,
            __error:
              err.response.data?.errors?.name ||
              'Only one organization is allowed in this system.',
          };
        }
        // Handle 400 validation errors
        if (err.response?.status === 400) {
          return {
            data: null,
            __error:
              err.response.data?.name?.[0] ||
              err.response.data?.error ||
              'Organization with this name may already exist.',
          };
        }
        throw err;
      });

      if (response.__error) {
        return fail(403, { error: { name: response.__error } });
      }

      // Response should contain the created org
      const newOrg = response.data.org || response.data;

      // Set org cookie for the newly created org
      await cookies.set('org', newOrg.id, {
        path: '/',
        httpOnly: true,
        sameSite: 'strict',
        secure: env.NODE_ENV === 'production'
      });

      // Return success
      return {
        data: {
          name: orgName
        }
      };
    } catch (err) {
      console.error('Error creating organization:', err);

      // Check if it's a duplicate name error
      if (err.response?.status === 400) {
        return {
          error: {
            name:
              err.response.data?.name?.[0] ||
              err.response.data?.error ||
              'Organization with this name may already exist'
          }
        };
      }

      return {
        error: {
          name: 'An unexpected error occurred while creating the organization.'
        }
      };
    }
  }
};
