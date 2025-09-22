import 'package:stopfire_mobile/features/stations/domain/entities/station.dart';

class StationModel {
  final int id;
  final int? idUsuario;
  final String nombre;
  final double lat;
  final double lon;
  final String? descripcionDireccion;
  final String? celular;
  final bool estado;
  final List<GeoPoint> cobertura;

  StationModel({
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

  factory StationModel.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['latitud']?.toString() ?? '') ?? 0;
    final lon = double.tryParse(json['longitud']?.toString() ?? '') ?? 0;

    final cov = <GeoPoint>[];
    final cobertura = json['cobertura'];
    if (cobertura is Map && cobertura['type'] == 'Polygon') {
      final coords = cobertura['coordinates'];
      if (coords is List && coords.isNotEmpty) {
        final ring = coords.first; 
        if (ring is List) {
          for (final item in ring) {
            if (item is List && item.length >= 2) {
              final lonNum = (item[0] as num).toDouble();
              final latNum = (item[1] as num).toDouble();
              cov.add(GeoPoint(lat: latNum, lon: lonNum));
            }
          }
        }
      }
    }

    return StationModel(
      id: json['id'] as int,
      idUsuario: json['idUsuario'] as int?,
      nombre: json['nombre']?.toString() ?? '',
      lat: lat,
      lon: lon,
      descripcionDireccion: json['descripcionDireccion']?.toString(),
      celular: json['celular']?.toString(),
      estado: (json['estado'] as bool?) ?? false,
      cobertura: cov,
    );
  }

  Station toEntity() => Station(
        id: id,
        idUsuario: idUsuario,
        nombre: nombre,
        lat: lat,
        lon: lon,
        descripcionDireccion: descripcionDireccion,
        celular: celular,
        estado: estado,
        cobertura: cobertura,
      );
}