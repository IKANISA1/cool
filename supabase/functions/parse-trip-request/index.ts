// supabase/functions/parse-trip-request/index.ts
// Edge Function for AI-powered trip request parsing via Gemini

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// Allowed origins for CORS
const ALLOWED_ORIGINS = [
    "https://ridelink.app",
    "https://www.ridelink.app",
    "https://app.ridelink.app",
    "http://localhost:3000",  // Development
    "http://localhost:8080",  // Flutter web dev
];

function getCorsHeaders(origin: string | null): HeadersInit {
    const allowedOrigin = origin && ALLOWED_ORIGINS.includes(origin)
        ? origin
        : ALLOWED_ORIGINS[0];

    return {
        "Access-Control-Allow-Origin": allowedOrigin,
        "Access-Control-Allow-Headers":
            "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Credentials": "true",
    };
}

interface TripRequest {
    input: string;
    inputType: "text" | "voice";
    audioData?: string; // Base64 encoded audio
    userLocation?: {
        latitude: number;
        longitude: number;
    };
}

interface ParsedTrip {
    origin: string;
    destination: string;
    departureTime: string;
    seats: number;
    vehiclePreference: string | null;
    originCoordinates?: { lat: number; lng: number };
    destinationCoordinates?: { lat: number; lng: number };
    confidence: number;
    suggestions?: string[];
}

// Known major cities in Sub-Saharan Africa (fallback geocoding)
const knownLocations: Record<string, { lat: number; lng: number }> = {
    kigali: { lat: -1.9441, lng: 30.0619 },
    huye: { lat: -2.5969, lng: 29.7389 },
    musanze: { lat: -1.4992, lng: 29.635 },
    rubavu: { lat: -1.6775, lng: 29.26 },
    nyagatare: { lat: -1.2986, lng: 30.3275 },
    muhanga: { lat: -2.0839, lng: 29.7528 },
    ruhango: { lat: -2.2167, lng: 29.7833 },
    nairobi: { lat: -1.2921, lng: 36.8219 },
    mombasa: { lat: -4.0435, lng: 39.6682 },
    kampala: { lat: 0.3476, lng: 32.5825 },
    "dar es salaam": { lat: -6.7924, lng: 39.2083 },
    bujumbura: { lat: -3.3614, lng: 29.3599 },
    gisenyi: { lat: -1.7028, lng: 29.2567 },
    butare: { lat: -2.5969, lng: 29.7389 }, // Same as Huye
    cyangugu: { lat: -2.4847, lng: 28.9075 },
    rwamagana: { lat: -1.9494, lng: 30.4347 },
    kayonza: { lat: -1.8608, lng: 30.6567 },
    byumba: { lat: -1.5764, lng: 30.0672 },
    gitarama: { lat: -2.0747, lng: 29.7567 }, // Muhanga old name
};

serve(async (req: Request): Promise<Response> => {
    const origin = req.headers.get("origin");
    const corsHeaders = getCorsHeaders(origin);

    // Handle CORS preflight
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        // Only allow POST requests
        if (req.method !== "POST") {
            return new Response(JSON.stringify({ error: "Method not allowed" }), {
                status: 405,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        const { input, inputType, audioData, userLocation }: TripRequest =
            await req.json();

        if (!input && !audioData) {
            return new Response(
                JSON.stringify({ error: "Input or audioData is required" }),
                {
                    status: 400,
                    headers: { ...corsHeaders, "Content-Type": "application/json" },
                }
            );
        }

        const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
        if (!geminiApiKey) {
            throw new Error("GEMINI_API_KEY not configured");
        }

        let textInput = input;

        // If voice input, transcribe first
        if (inputType === "voice" && audioData) {
            textInput = await transcribeAudio(audioData, geminiApiKey);
        }

        // Parse the trip request
        const parsedTrip = await parseTripRequest(
            textInput,
            userLocation,
            geminiApiKey
        );

        return new Response(JSON.stringify(parsedTrip), {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    } catch (error) {
        console.error("Error:", error);
        return new Response(
            JSON.stringify({
                error: error instanceof Error ? error.message : "An unexpected error occurred",
            }),
            {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
        );
    }
});

async function transcribeAudio(
    audioData: string,
    apiKey: string
): Promise<string> {
    // Use Gemini's multimodal capabilities for transcription
    const prompt = `
Transcribe this audio input accurately. 
The audio is about a trip request in Rwanda, Kenya, Uganda, Tanzania, or Burundi.
Common place names include: Kigali, Huye, Musanze, Nairobi, Kampala, Dar es Salaam, etc.
Return only the transcribed text, nothing else.
`;

    const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${apiKey}`,
        {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                contents: [
                    {
                        parts: [
                            { text: prompt },
                            {
                                inline_data: {
                                    mime_type: "audio/wav",
                                    data: audioData,
                                },
                            },
                        ],
                    },
                ],
                generationConfig: {
                    temperature: 0.2,
                    maxOutputTokens: 256,
                },
            }),
        }
    );

    if (!response.ok) {
        const errorData = await response.json();
        console.error("Gemini transcription error:", errorData);
        throw new Error("Failed to transcribe audio");
    }

    const result = await response.json();
    return result.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "";
}

async function parseTripRequest(
    input: string,
    userLocation: { latitude: number; longitude: number } | undefined,
    apiKey: string
): Promise<ParsedTrip> {
    const today = new Date();
    const todayStr = today.toISOString().split("T")[0];
    const currentTime = today.toTimeString().split(" ")[0].substring(0, 5);

    const prompt = `
You are a trip scheduling assistant for a ride-sharing app in Sub-Saharan Africa (Rwanda, Kenya, Uganda, Tanzania, Burundi).

Current context:
- Today's date: ${todayStr}
- Current time: ${currentTime}
${userLocation ? `- User's current location: ${userLocation.latitude}, ${userLocation.longitude}` : ""}

Parse the following trip request and extract structured information.

User input: "${input}"

Instructions:
1. Extract origin and destination city/location names
2. Infer departure time from context:
   - "tomorrow" = next day at 08:00
   - "morning" = today/tomorrow at 08:00
   - "afternoon" = today/tomorrow at 14:00
   - "evening" = today/tomorrow at 18:00
   - "now" or "immediately" = current time
   - Specific times like "3pm" or "15:00" = that time today (or tomorrow if already past)
3. Extract number of seats (default to 1 if not mentioned)
4. Extract vehicle preference if mentioned (Moto Taxi, Cab, Liffan, Truck, Rent, Other)
5. Provide confidence score (0-100) based on clarity of the request
6. Generate 2-3 helpful suggestions for the trip

Respond with ONLY valid JSON in this exact format (no markdown, no code blocks):
{
  "origin": "city/location name",
  "destination": "city/location name",
  "departureTime": "YYYY-MM-DDTHH:mm:ss",
  "seats": number,
  "vehiclePreference": "vehicle type or null",
  "confidence": number (0-100),
  "suggestions": ["suggestion 1", "suggestion 2", "suggestion 3"]
}
`;

    const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${apiKey}`,
        {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: {
                    temperature: 0.4,
                    topP: 0.95,
                    topK: 40,
                    maxOutputTokens: 2048,
                },
            }),
        }
    );

    if (!response.ok) {
        const errorData = await response.json();
        console.error("Gemini parse error:", errorData);
        throw new Error("Failed to parse trip request");
    }

    const result = await response.json();
    const responseText =
        result.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "";

    // Clean up response (remove markdown code blocks if present)
    const cleanJson = responseText
        .replace(/```json\n?/g, "")
        .replace(/```\n?/g, "")
        .trim();

    let parsed: ParsedTrip;
    try {
        parsed = JSON.parse(cleanJson);
    } catch (_e) {
        console.error("Failed to parse AI response:", cleanJson);
        throw new Error(`Failed to parse AI response: ${cleanJson.substring(0, 100)}`);
    }

    // Geocode locations
    if (parsed.origin) {
        const originCoords = await geocodeLocation(parsed.origin);
        if (originCoords) {
            parsed.originCoordinates = originCoords;
        }
    }

    if (parsed.destination) {
        const destCoords = await geocodeLocation(parsed.destination);
        if (destCoords) {
            parsed.destinationCoordinates = destCoords;
        }
    }

    return parsed;
}

async function geocodeLocation(
    locationName: string
): Promise<{ lat: number; lng: number } | null> {
    const normalized = locationName.toLowerCase().trim();

    // Check known locations first (fast path)
    if (knownLocations[normalized]) {
        return knownLocations[normalized];
    }

    // Try Nominatim (OpenStreetMap) as fallback
    try {
        const response = await fetch(
            `https://nominatim.openstreetmap.org/search?` +
            `q=${encodeURIComponent(locationName)}&format=json&limit=1`,
            {
                headers: {
                    "User-Agent": "RideLink-App/1.0",
                },
            }
        );

        const data = await response.json();

        if (data && data.length > 0) {
            return {
                lat: parseFloat(data[0].lat),
                lng: parseFloat(data[0].lon),
            };
        }
    } catch (e) {
        console.error("Geocoding error:", e);
    }

    return null;
}
