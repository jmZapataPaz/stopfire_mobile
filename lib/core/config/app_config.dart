class AppConfig {
  static const String baseUrl = 'http://172.16.10.124:5190';
  static const String loginEndpoint = '/api/Usuarios/login';
  static const String stationsEndpoint = '/api/Usuarios/estaciones';
  static const String registerInitEndpoint = '/api/Usuarios/registrar/iniciar';
  static const String registerVerifyEndpoint = '/api/Usuarios/registrar/verificar';
  static const String reportCreateEndpoint = '/api/Usuarios/reportes';
  static const bool httpVerboseLogging = true;
  static const bool httpLogSensitive = false;
}