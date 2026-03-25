import { createClient } from '@supabase/supabase-js';

export interface Env {
  SUPABASE_URL: string;
  SUPABASE_KEY: string;
  JWT_SECRET: string;
}

export function getDB(env: Env) {
  return createClient(env.SUPABASE_URL, env.SUPABASE_KEY);
}

export type DB = ReturnType<typeof getDB>;
