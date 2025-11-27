class AppConfig {
  static const String baseUrl = 'http://10.26.3.53:5190';
  static const String loginEndpoint = '/api/Usuarios/login';
  static const String stationsEndpoint = '/api/Usuarios/estaciones';
  static const String registerInitEndpoint = '/api/Usuarios/registrar/iniciar';
  static const String registerVerifyEndpoint = '/api/Usuarios/registrar/verificar';
  static const String reportCreateEndpoint = '/api/Usuarios/reportes';
  static const String passwordRecoverInitEndpoint = '/api/Usuarios/contrasena/recuperar/iniciar'; 
  static const String passwordRecoverVerifyEndpoint = '/api/Usuarios/contrasena/recuperar/verificar'; 
  static const bool httpVerboseLogging = true;
  static const bool httpLogSensitive = false;
}