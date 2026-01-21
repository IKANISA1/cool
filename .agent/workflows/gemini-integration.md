---
description: 
---

/gemini-integration

Implement complete Gemini AI integration:

1. GEMINI SERVICE (Flutter)
   Create: lib/shared/services/gemini_service.dart
   
   Methods:
   - parseTripRequest(String input)
   - parseTripRequestViaEdge(input, type, audio, location)
   - generateTripSuggestions(origin, destination)
   - enhanceSearchQuery(String query)
   - transcribeVoice(audioData)
   
   Features:
   - Error handling
   - Retry logic
   - Caching common responses
   - Rate limiting
   - Timeout handling (10s)

2. EDGE FUNCTION IMPLEMENTATION
   File: supabase/functions/parse-trip-request/index.ts
   
   Capabilities:
   - Accept text or voice input
   - Transcribe audio using Gemini multimodal
   - Parse natural language into structured data
   - Geocode locations (Nominatim + known cities)
   - Generate confidence scores
   - Provide contextual suggestions
   
   Input validation:
   - Max input length
   - Supported languages
   - Audio format restrictions
   
   Output format:
```json
   {
     "origin": "city name",
     "destination": "city name",
     "departureTime": "ISO 8601",
     "seats": number,
     "vehiclePreference": "type or null",
     "confidence": 0-100,
     "suggestions": ["tip1", "tip2"],
     "originCoordinates": {lat, lng},
     "destinationCoordinates": {lat, lng}
   }
```

3. GEMINI PROMPTS
   Create optimized prompts:
   
   a) Trip Parsing Prompt
      - Context about East Africa
      - Known city names
      - Time inference rules
      - Output format specification
      - Examples for few-shot learning
   
   b) Suggestion Generation Prompt
      - Travel tips
      - Safety advice
      - Route conditions
      - Best times
   
   c) Voice Transcription Prompt
      - Accent handling
      - Noise tolerance
      - Place name recognition

4. VOICE INPUT INTEGRATION
   Implement speech-to-text:
   - Use speech_to_text package
   - Handle permissions
   - Visual feedback (waveform)
   - Error states
   - Fallback to manual input

5. SCHEDULE SCREEN AI MODE
   Connect AI to UI:
   - Voice button triggers recording
   - Send to Edge Function
   - Display parsed result
   - Allow editing
   - Confirm and save
   - Show suggestions

6. CACHING STRATEGY
   - Cache city coordinates
   - Store recent queries
   - Offline fallback data
   - LRU cache implementation

7. MONITORING
   - Log AI requests
   - Track success rates
   - Monitor latency
   - Alert on failures

Testing:
- Test with various phrasings
- Multiple languages
- Edge cases (ambiguous input)
- Voice quality variations
- Network failures
- Rate limit handling

Artifacts:
- AI integration flow diagram
- Sample prompts and responses
- Performance metrics
- Error handling documentation