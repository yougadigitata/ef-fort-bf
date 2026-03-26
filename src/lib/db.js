import { createClient } from '@supabase/supabase-js';
export function getDB(env) {
    return createClient(env.SUPABASE_URL, env.SUPABASE_KEY);
}
