class ReportHistory {
  final int idReporte;
  final String descripcion;
  final String nombreCompleto;
  final String ci;
  final String celular;
  final double latitud;
  final double longitud;
  final String fotoUrl;
  final DateTime fechaCreacion;

  ReportHistory({
    required this.idReporte,
    required this.descripcion,
    required this.nombreCompleto,
    required this.ci,
    required this.celular,
    required this.latitud,
    required this.longitud,
    required this.fotoUrl,
    required this.fechaCreacion,
  });

  factory ReportHistory.fromJson(Map<String, dynamic> j) => ReportHistory(
    idReporte: j['idReporte'],
    descripcion: j['descripcion'] ?? '',
    nombreCompleto: j['nombreCompleto'] ?? '',
    ci: j['ci'] ?? '',
    celular: j['celular'] ?? '',
    latitud: (j['latitud'] ?? 0).toDouble(),
    longitud: (j['longitud'] ?? 0).toDouble(),
    fotoUrl: j['fotoUrl'] ?? '',
    fechaCreacion: DateTime.parse(j['fechaCreacion']),
  );
}