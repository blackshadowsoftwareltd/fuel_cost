class ErrorUtils {
  /// Sanitizes error messages by removing HTML tags and providing user-friendly messages
  static String sanitizeErrorMessage(String rawError) {
    // Remove HTML tags
    String cleanError = rawError.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Remove excessive whitespace
    cleanError = cleanError.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // If the error message is too long or contains HTTP-like content, provide a generic message
    if (cleanError.length > 200 || 
        cleanError.toLowerCase().contains('<!doctype') ||
        cleanError.toLowerCase().contains('<html') ||
        cleanError.toLowerCase().contains('nginx') ||
        cleanError.toLowerCase().contains('apache') ||
        cleanError.toLowerCase().contains('server error') ||
        cleanError.toLowerCase().contains('internal server error')) {
      return 'Server temporarily unavailable. Please try again later.';
    }
    
    // Check for common HTTP status codes and provide friendly messages
    if (cleanError.contains('400')) {
      return 'Invalid request. Please check your data and try again.';
    } else if (cleanError.contains('401')) {
      return 'Authentication required. Please sign in again.';
    } else if (cleanError.contains('403')) {
      return 'Access denied. Please check your permissions.';
    } else if (cleanError.contains('404')) {
      return 'Resource not found. Please try again.';
    } else if (cleanError.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (cleanError.contains('502') || cleanError.contains('503') || cleanError.contains('504')) {
      return 'Server temporarily unavailable. Please try again later.';
    }
    
    // If it's empty after sanitization, provide a generic message
    if (cleanError.isEmpty) {
      return 'An unexpected error occurred. Please try again.';
    }
    
    // Return the clean error if it seems reasonable
    return cleanError;
  }

  /// Extracts user-friendly error message from HTTP response
  static String extractErrorFromResponse(String responseBody, int statusCode) {
    try {
      // Try to parse as JSON first
      final Map<String, dynamic> errorData = 
          responseBody.startsWith('{') ? 
          Map<String, dynamic>.from(
            responseBody.split(',').fold<Map<String, dynamic>>({}, (map, pair) {
              final parts = pair.split(':');
              if (parts.length == 2) {
                map[parts[0].trim().replaceAll(RegExp(r'[{"}]'), '')] = 
                    parts[1].trim().replaceAll(RegExp(r'[}"]'), '');
              }
              return map;
            })
          ) : {};
      
      if (errorData.containsKey('message')) {
        return sanitizeErrorMessage(errorData['message'].toString());
      }
    } catch (e) {
      // JSON parsing failed, treat as raw text
    }
    
    // Fallback to sanitizing the raw response
    return sanitizeErrorMessage(responseBody);
  }

  /// Checks if an error is network-related
  static bool isNetworkError(String error) {
    return error.toLowerCase().contains('socketexception') ||
           error.toLowerCase().contains('timeoutexception') ||
           error.toLowerCase().contains('connection') ||
           error.toLowerCase().contains('network');
  }

  /// Gets a user-friendly network error message
  static String getNetworkErrorMessage() {
    return 'Cannot connect to server. Please check your internet connection.';
  }
}