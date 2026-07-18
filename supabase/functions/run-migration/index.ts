import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-migration-secret',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const secret = req.headers.get('x-migration-secret')
  if (secret !== 'ef-fort-migrate-2025') {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const results: string[] = []

  // Exécuter le SQL via pg directement (Edge Functions ont accès à SUPABASE_DB_URL)
  const dbUrl = Deno.env.get('SUPABASE_DB_URL')
  
  if (!dbUrl) {
    return new Response(JSON.stringify({ 
      error: 'SUPABASE_DB_URL non disponible',
      note: 'Utiliser Supabase CLI pour déployer cette fonction'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  return new Response(JSON.stringify({ 
    success: true, 
    results,
    db_url_available: !!dbUrl
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  })
})
