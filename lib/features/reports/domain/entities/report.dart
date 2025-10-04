class Report {
  final int id;
  final String? descripcion;
  final String? fotoUrl;
  final double? lat;
  final double? lon;
  final String? estado;

  Report({
    required this.id,
    this.descripcion,
    this.fotoUrl,
    this.lat,
    this.lon,
    this.estado,
  });
}