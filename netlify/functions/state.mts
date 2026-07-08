import type { Config, Context } from '@netlify/functions';
import { getStore } from '@netlify/blobs';

const STORE_NAME = 'gate-ece-tracker';
const KEY = 'state';

export default async (req: Request, context: Context) => {
  const store = getStore(STORE_NAME);

  if (req.method === 'GET') {
    const value = await store.get(KEY, { type: 'json' });
    return Response.json({ value });
  }

  if (req.method === 'PUT') {
    const body = await req.json();
    await store.setJSON(KEY, body);
    return Response.json({ ok: true });
  }

  return new Response('Method not allowed', { status: 405 });
};

export const config: Config = {
  path: '/api/state',
};
