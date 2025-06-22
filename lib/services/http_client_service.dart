import 'dart:io';
import 'package:http/http.dart' as http;

class HttpClientService {
  static http.Client? _client;
  
  static http.Client get client {
    if (_client == null) {
      _client = http.Client();
      
      // For Android release builds, we need to handle certificate issues
      if (Platform.isAndroid) {
        HttpOverrides.global = MyHttpOverrides();
      }
    }
    return _client!;
  }
  
  static void dispose() {
    _client?.close();
    _client = null;
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    // For development/testing - in production you should use proper certificates
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // For localhost/development servers, allow bad certificates
      if (host == '127.0.0.1' || host == 'localhost' || host == '10.0.2.2') {
        return true;
      }
      
      // For production, you should validate certificates properly
      return false;
    };
    
    // Increase timeout for better reliability
    client.connectionTimeout = const Duration(seconds: 30);
    
    return client;
  }
}