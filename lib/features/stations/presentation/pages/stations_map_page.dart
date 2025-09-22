import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stopfire_mobile/features/stations/presentation/state/station_provider.dart';
import 'package:stopfire_mobile/features/stations/domain/entities/station.dart';
import 'package:stopfire_mobile/features/account/presentation/pages/account_page.dart';

class StationsMapPage extends StatefulWidget {
  const StationsMapPage({super.key});

  @override
  State<StationsMapPage> createState() => _StationsMapPageState();
}

class _StationsMapPageState extends State<StationsMapPage> {
  final MapController _mapController = MapController();
  bool _centeredToUserLocationOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StationProvider>().loadStations();
      _centerToUserLocationOnce();
    });
  }

  LatLng _defaultCenter() => const LatLng(-17.81753, -63.22008);
  Future<void> _centerToUserLocationOnce() async {
    if (_centeredToUserLocationOnce) return;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latLng, 15);
      _centeredToUserLocationOnce = true;
    } catch (_) {
    }
  }
  Color _colorForIndex(int i) {
    final h = (i * 67) % 360.0; 
    return HSLColor.fromAHSL(1.0, h.toDouble(), 0.65, 0.52).toColor();
  }
  void _showStationInfo(Station s) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (s.descripcionDireccion != null && s.descripcionDireccion!.isNotEmpty)
              Text(s.descripcionDireccion!),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone, size: 18),
                const SizedBox(width: 6),
                Text((s.celular ?? '-').isEmpty ? '-' : s.celular!),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StationProvider>(
      builder: (context, sp, _) {
        final hasData = sp.stations.isNotEmpty;
        final polygons = <Polygon>[];
        final circleMarkers = <CircleMarker>[];
        for (var i = 0; i < sp.stations.length; i++) {
          final s = sp.stations[i];
          if (s.cobertura.isEmpty) continue;
          final color = _colorForIndex(i);
          final pts = s.cobertura.map((p) => LatLng(p.lat, p.lon)).toList();
          final fillColor = color.withAlpha(85);    
          polygons.add(
            Polygon(
              points: pts,
              isFilled: true,
              color: fillColor,            
              borderColor: color,          
              borderStrokeWidth: 2,
            ),
          );
        }
        final markers = sp.stations
            .map(
              (s) => Marker(
                point: LatLng(s.lat, s.lon),
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () => _showStationInfo(s),
                  child: const Tooltip(
                    message: 'Estación',
                    child: Icon(Icons.fire_truck_rounded, color: Colors.red, size: 36),
                  ),
                ),
              ),
            )
            .toList();

        final center = hasData ? LatLng(sp.stations.first.lat, sp.stations.first.lon) : _defaultCenter();

        return Scaffold(
          body: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.stopfire_mobile',
                subdomains: const ['a', 'b', 'c'],
                retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
              ),
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: Colors.blueAccent,
                    child: Icon(Icons.my_location, color: Colors.white, size: 16),
                  ),
                  markerSize: Size(32, 32),
                  accuracyCircleColor: Color(0x330000FF),
                ),
              ),
              if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
              if (circleMarkers.isNotEmpty) CircleLayer(circles: circleMarkers),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
              if (sp.loading)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              if (sp.error != null && !sp.loading)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(sp.error!, style: const TextStyle(color: Colors.red)),
                  ),
                ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'fit',
                onPressed: () {
                  final allPoints = <LatLng>[];
                  for (final p in polygons) {
                    allPoints.addAll(p.points);
                  }
                  for (final m in markers) {
                    allPoints.add(m.point);
                  }
                  if (allPoints.isNotEmpty) {
                    final fit = CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(allPoints),
                      padding: const EdgeInsets.all(32),
                    );
                    _mapController.fitCamera(fit);
                  }
                },
                child: const Icon(Icons.fit_screen),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 0,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Cuenta'),
            ],
            onDestinationSelected: (i) {
              if (i == 1) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AccountPage()),
                );
              }
            },
          ),
        );
      },
    );
  }
}