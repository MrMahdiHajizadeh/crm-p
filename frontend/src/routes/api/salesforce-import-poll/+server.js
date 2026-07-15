import { json } from '@sveltejs/kit';

/** @type {import('./$types').RequestHandler} */
export async function GET() {
  // Salesforce integration was moved to enterprise edition.
  return json({ job: null, jobs: [] });
}
