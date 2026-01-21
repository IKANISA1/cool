import { serve } from "std/http/server.ts"
import { createClient } from "@supabase/supabase-js"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_ANON_KEY') ?? '',
            { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
        )

        const { origin_lat, origin_lng, dest_lat, dest_lng, time_window_start, time_window_end } = await req.json()

        if (!origin_lat || !origin_lng) {
            throw new Error('Missing location data')
        }

        // Call database function to find matches
        // This assumes a 'match_trips' RPC exists (we should create it in migration)
        // Or we can query directly

        // Simple proximity search for now using Supabase helper
        // Finding trips that start near origin and end near destination within time window

        // Using a hypothetic RPC 'find_matching_trips'
        const { data: matches, error } = await supabaseClient
            .rpc('find_matching_trips', {
                start_lat: origin_lat,
                start_lng: origin_lng,
                end_lat: dest_lat,
                end_lng: dest_lng,
                window_start: time_window_start, // ISO string
                window_end: time_window_end, // ISO string
                radius_meters: 1000 // 1km tolerance
            })

        if (error) throw error

        return new Response(JSON.stringify({ matches }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
        })

    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        })
    }
})
