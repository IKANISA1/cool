import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface FetchStationsRequest {
    latitude: number
    longitude: number
    radius: number // in meters
    stationType: 'battery_swap' | 'ev_charging'
}

serve(async (req) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { latitude, longitude, radius, stationType }: FetchStationsRequest =
            await req.json()

        // Validate inputs
        if (!latitude || !longitude) {
            throw new Error('latitude and longitude are required')
        }

        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const googleApiKey = Deno.env.get('GOOGLE_MAPS_API_KEY')
        if (!googleApiKey) {
            throw new Error('GOOGLE_MAPS_API_KEY not configured')
        }

        // Determine search type for Google Places API
        const includedTypes = stationType === 'ev_charging'
            ? ['electric_vehicle_charging_station']
            : ['gas_station'] // Fallback for battery swap (manual curation needed in Africa)

        // Call Google Places API (New) - Nearby Search
        const placesResponse = await fetch(
            'https://places.googleapis.com/v1/places:searchNearby',
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Goog-Api-Key': googleApiKey,
                    'X-Goog-FieldMask': [
                        'places.id',
                        'places.displayName',
                        'places.formattedAddress',
                        'places.location',
                        'places.types',
                        'places.rating',
                        'places.userRatingCount',
                        'places.internationalPhoneNumber',
                        'places.websiteUri',
                        'places.regularOpeningHours',
                        'places.evChargeOptions'
                    ].join(',')
                },
                body: JSON.stringify({
                    includedTypes,
                    locationRestriction: {
                        circle: {
                            center: { latitude, longitude },
                            radius: radius || 10000
                        }
                    },
                    maxResultCount: 20,
                    rankPreference: 'DISTANCE'
                })
            }
        )

        if (!placesResponse.ok) {
            const error = await placesResponse.json()
            console.error('Google Places API error:', error)
            throw new Error(`Google Places API error: ${JSON.stringify(error)}`)
        }

        const placesData = await placesResponse.json()
        const places = placesData.places || []

        // Process and store/update stations in database
        const processedStations = []

        for (const place of places) {
            if (stationType === 'ev_charging') {
                const connectorTypes = place.evChargeOptions?.connectorAggregation || []

                const stationData = {
                    name: place.displayName?.text || 'Unknown Station',
                    network: extractNetwork(place.displayName?.text),
                    address: place.formattedAddress || '',
                    city: extractCity(place.formattedAddress),
                    country: 'RWA', // Default for now, can be extracted from address
                    latitude: place.location?.latitude,
                    longitude: place.location?.longitude,
                    location: `POINT(${place.location?.longitude} ${place.location?.latitude})`,
                    google_place_id: place.id,
                    source: 'google_places',
                    average_rating: place.rating || 0,
                    total_ratings: place.userRatingCount || 0,
                    phone_number: place.internationalPhoneNumber,
                    website: place.websiteUri,
                    operating_hours: formatOpeningHours(place.regularOpeningHours),
                    is_24_hours: is24Hours(place.regularOpeningHours),
                    connector_types: connectorTypes.map((c: any) => ({
                        type: c.type,
                        count: (c.availabilityCount || 0) + (c.outOfServiceCount || 0),
                        available: c.availabilityCount || 0,
                        max_charge_rate_kw: c.maxChargeRateKw || 0
                    })),
                    max_power_kw: Math.max(0, ...connectorTypes.map((c: any) => c.maxChargeRateKw || 0)),
                    total_ports: connectorTypes.reduce((sum: number, c: any) =>
                        sum + (c.availabilityCount || 0) + (c.outOfServiceCount || 0), 0),
                    available_ports: connectorTypes.reduce((sum: number, c: any) =>
                        sum + (c.availabilityCount || 0), 0),
                    last_availability_update: new Date().toISOString(),
                    verified: true,
                    verified_at: new Date().toISOString(),
                    is_operational: true
                }

                // Upsert to database
                const { data, error } = await supabaseClient
                    .from('ev_charging_stations')
                    .upsert(stationData, {
                        onConflict: 'google_place_id',
                        ignoreDuplicates: false
                    })
                    .select()

                if (error) {
                    console.error('Database upsert error:', error)
                } else if (data) {
                    processedStations.push(data[0])
                }
            }
        }

        return new Response(
            JSON.stringify({
                success: true,
                stations: processedStations,
                count: processedStations.length,
                raw_count: places.length
            }),
            {
                status: 200,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            }
        )

    } catch (error) {
        console.error('Error:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            {
                status: 500,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            }
        )
    }
})

// Helper functions
function extractNetwork(displayName: string | undefined): string {
    if (!displayName) return 'Independent'

    const networks = [
        'ChargePoint', 'Tesla', 'EVgo', 'Electrify America', 'Blink',
        'Shell Recharge', 'BP Pulse', 'Ionity', 'Ampersand'
    ]

    for (const network of networks) {
        if (displayName.toLowerCase().includes(network.toLowerCase())) {
            return network
        }
    }
    return 'Independent'
}

function extractCity(address: string | undefined): string {
    if (!address) return ''

    // Simple extraction - get second-to-last comma-separated part
    const parts = address.split(',').map(p => p.trim())
    if (parts.length >= 2) {
        return parts[parts.length - 2]
    }
    return ''
}

function formatOpeningHours(hours: any): any {
    if (!hours?.periods) return null

    const formatted: any = {}
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']

    hours.periods.forEach((period: any) => {
        const day = days[period.open?.day || 0]
        const open = period.open
            ? `${String(period.open.hour).padStart(2, '0')}:${String(period.open.minute || 0).padStart(2, '0')}`
            : null
        const close = period.close
            ? `${String(period.close.hour).padStart(2, '0')}:${String(period.close.minute || 0).padStart(2, '0')}`
            : null

        formatted[day] = open && close ? `${open}-${close}` : '24 hours'
    })

    return formatted
}

function is24Hours(hours: any): boolean {
    if (!hours?.periods) return false

    // Check if any period spans 24 hours
    return hours.periods.some((period: any) => {
        if (!period.open || !period.close) return true
        return period.open.hour === 0 && period.open.minute === 0 &&
            period.close.hour === 23 && period.close.minute === 59
    })
}
