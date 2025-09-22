class GeoPoint {
  final double lat;
  final double lon;
  const GeoPoint({required this.lat, required this.lon});
}

class Station {
  final int id;
  final int? idUsuario;
  final String nombre;
  final double lat;
  final double lon;
  final String? descripcionDireccion;
  final String? celular;
  final bool estado;
  final List<GeoPoint> cobertura; 

  const Station({
    required this.id,
    this.idUsuario,
    required this.nombre,
    required this.lat,
    required this.lon,
    this.descripcionDireccion,
    this.celular,
    required this.estado,
    required this.cobertura,
  });
}