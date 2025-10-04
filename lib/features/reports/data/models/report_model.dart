class ReportModel {
  final int id;
  final String? descripcion;
  final String? fotoUrl;
  final double? latitud;
  final double? longitud;
  final String? estado;
  final String? fechaCreacion;

  ReportModel({
    required this.id,
    this.descripcion,
    this.fotoUrl,
    this.latitud,
    this.longitud,
    this.estado,
    this.fechaCreacion,
  });

  factory ReportModel.fromJson(Map<String, dynamic> j) {
    double? _toD(v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }
    return ReportModel(
      id: (j['id'] ?? j['Id'] ?? 0) as int,
      descripcion: j['descripcion'] ?? j['Descripcion'],
      fotoUrl: j['fotoUrl'] ?? j['FotoUrl'] ?? j['imagenUrl'] ?? j['ImagenUrl'],
      latitud: _toD(j['latitud'] ?? j['Latitud']),
      longitud: _toD(j['longitud'] ?? j['Longitud']),
      estado: j['estado'] ?? j['Estado'],
      fechaCreacion: j['fechaCreacion']?.toString() ?? j['FechaCreacion']?.toString(),
    );
  }
}