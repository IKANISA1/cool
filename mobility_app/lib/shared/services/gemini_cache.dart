// ============================================================================
// GEMINI CACHE - shared/services/gemini_cache.dart
// LRU cache for city coordinates and AI responses with TTL support
// ============================================================================

import 'dart:collection';

/// LRU Cache entry with timestamp for TTL
class _CacheEntry<T> {
  final T value;
  final DateTime createdAt;

  _CacheEntry(this.value) : createdAt = DateTime.now();

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(createdAt) > ttl;
  }
}

/// LRU Cache with optional TTL support
class LRUCache<K, V> {
  final int maxSize;
  final Duration? ttl;
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();

  LRUCache({required this.maxSize, this.ttl});

  /// Get value from cache, returns null if not found or expired
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Check TTL if configured
    if (ttl != null && entry.isExpired(ttl!)) {
      _cache.remove(key);
      return null;
    }
    
    // Move to end (most recently used)
    _cache.remove(key);
    _cache[key] = entry;
    return entry.value;
  }

  /// Put value in cache, evicting oldest if at capacity
  void put(K key, V value) {
    // Remove if exists (to update position)
    _cache.remove(key);
    
    // Evict oldest if at capacity
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    
    _cache[key] = _CacheEntry(value);
  }

  /// Check if key exists and is not expired
  bool containsKey(K key) => get(key) != null;

  /// Clear all entries
  void clear() => _cache.clear();

  /// Current cache size
  int get length => _cache.length;

  /// Remove expired entries (call periodically if needed)
  void evictExpired() {
    if (ttl == null) return;
    _cache.removeWhere((_, entry) => entry.isExpired(ttl!));
  }
}

/// Coordinates data class
class CachedCoordinates {
  final double lat;
  final double lng;

  const CachedCoordinates({required this.lat, required this.lng});
  
  @override
  String toString() => '($lat, $lng)';
}

/// Gemini Cache Manager
/// Provides caching for city coordinates and AI responses
class GeminiCache {
  // City coordinate cache (LRU, 100 entries, no TTL - coordinates don't change)
  final LRUCache<String, CachedCoordinates> _coordCache = LRUCache(maxSize: 100);
  
  // Response cache (LRU, 50 entries, 5 minute TTL)
  final LRUCache<String, Map<String, dynamic>> _responseCache = LRUCache(
    maxSize: 50,
    ttl: const Duration(minutes: 5),
  );
  
  // Known locations for fast geocoding (Sub-Saharan Africa)
  static const Map<String, CachedCoordinates> _knownLocations = {
    'kigali': CachedCoordinates(lat: -1.9441, lng: 30.0619),
    'huye': CachedCoordinates(lat: -2.5969, lng: 29.7389),
    'musanze': CachedCoordinates(lat: -1.4992, lng: 29.635),
    'rubavu': CachedCoordinates(lat: -1.6775, lng: 29.26),
    'nyagatare': CachedCoordinates(lat: -1.2986, lng: 30.3275),
    'muhanga': CachedCoordinates(lat: -2.0839, lng: 29.7528),
    'ruhango': CachedCoordinates(lat: -2.2167, lng: 29.7833),
    'nairobi': CachedCoordinates(lat: -1.2921, lng: 36.8219),
    'mombasa': CachedCoordinates(lat: -4.0435, lng: 39.6682),
    'kampala': CachedCoordinates(lat: 0.3476, lng: 32.5825),
    'dar es salaam': CachedCoordinates(lat: -6.7924, lng: 39.2083),
    'bujumbura': CachedCoordinates(lat: -3.3614, lng: 29.3599),
    'gisenyi': CachedCoordinates(lat: -1.7028, lng: 29.2567),
    'butare': CachedCoordinates(lat: -2.5969, lng: 29.7389),
    'cyangugu': CachedCoordinates(lat: -2.4847, lng: 28.9075),
    'rwamagana': CachedCoordinates(lat: -1.9494, lng: 30.4347),
    'kayonza': CachedCoordinates(lat: -1.8608, lng: 30.6567),
    'byumba': CachedCoordinates(lat: -1.5764, lng: 30.0672),
    'gitarama': CachedCoordinates(lat: -2.0747, lng: 29.7567),
    'kimironko': CachedCoordinates(lat: -1.9389, lng: 30.1028),
    'remera': CachedCoordinates(lat: -1.9542, lng: 30.1039),
    'nyabugogo': CachedCoordinates(lat: -1.9367, lng: 30.0472),
    'kacyiru': CachedCoordinates(lat: -1.9306, lng: 30.0792),
    'kimihurura': CachedCoordinates(lat: -1.9500, lng: 30.0833),
    'nyamirambo': CachedCoordinates(lat: -1.9708, lng: 30.0442),
    'gikondo': CachedCoordinates(lat: -1.9683, lng: 30.0583),
    'kicukiro': CachedCoordinates(lat: -1.9794, lng: 30.0833),
  };

  /// Get coordinates for a location (checks known locations first, then cache)
  CachedCoordinates? getCoordinates(String location) {
    final normalized = location.toLowerCase().trim();
    
    // Check known locations first
    if (_knownLocations.containsKey(normalized)) {
      return _knownLocations[normalized];
    }
    
    // Check dynamic cache
    return _coordCache.get(normalized);
  }

  /// Cache coordinates for a location
  void cacheCoordinates(String location, double lat, double lng) {
    final normalized = location.toLowerCase().trim();
    _coordCache.put(normalized, CachedCoordinates(lat: lat, lng: lng));
  }

  /// Get cached response for a query
  Map<String, dynamic>? getResponse(String query) {
    final key = _normalizeQuery(query);
    return _responseCache.get(key);
  }

  /// Cache a response for a query
  void cacheResponse(String query, Map<String, dynamic> response) {
    final key = _normalizeQuery(query);
    _responseCache.put(key, response);
  }

  /// Check if we have a cached response
  bool hasResponse(String query) {
    return _responseCache.containsKey(_normalizeQuery(query));
  }

  /// Normalize query for cache key
  String _normalizeQuery(String query) {
    return query.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Clear all caches
  void clearAll() {
    _coordCache.clear();
    _responseCache.clear();
  }

  /// Get cache stats for monitoring
  Map<String, int> getStats() {
    return {
      'coordCacheSize': _coordCache.length,
      'responseCacheSize': _responseCache.length,
      'knownLocations': _knownLocations.length,
    };
  }
}
