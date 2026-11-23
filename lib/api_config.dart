import 'package:flutter/foundation.dart';

/// URL del backend Spring Boot (market-backend, puerto 8090).
///
/// - Emulador Android: http://10.0.2.2:8090 (por defecto en Android)
/// - Web / simulador iOS / escritorio: http://localhost:8090
/// - Celular físico: flutter run --dart-define=API_URL=http://IP_DE_TU_PC:8090
class ApiConfig {
  static const String _override = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8090';
    }
    return 'http://localhost:8090';
  }
}
