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

        const { amount, currency, recipient_id, method, metadata } = await req.json()
        const { data: { user } } = await supabaseClient.auth.getUser()

        if (!user) throw new Error('Unauthorized')
        if (!amount || !recipient_id) throw new Error('Missing payment details')

        // Call database function to atomic process payment
        const { data: transaction, error } = await supabaseClient
            .rpc('process_payment', {
                p_from_user: user.id,
                p_to_user: recipient_id,
                p_amount: amount,
                p_currency: currency || 'RWF',
                p_method: method || 'wallet',
                p_metadata: metadata || {}
            })

        if (error) throw error

        return new Response(JSON.stringify({ transaction }), {
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
