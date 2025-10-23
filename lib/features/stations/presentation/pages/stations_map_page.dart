import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stopfire_mobile/core/realtime/notificaciones_hub.dart';
import 'package:stopfire_mobile/features/stations/presentation/state/station_provider.dart';
import 'package:stopfire_mobile/features/stations/domain/entities/station.dart';
import 'package:stopfire_mobile/features/reports/presentation/pages/create_report_sheet.dart';
import 'package:stopfire_mobile/features/reports/presentation/state/report_provider.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/auth_provider.dart';
import 'package:stopfire_mobile/features/shared/widgets/app_bottom_nav_bar.dart';
import 'package:stopfire_mobile/core/config/app_config.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class StationsMapPage extends StatefulWidget {
  const StationsMapPage({
    super.key,
    this.focusLat,
    this.focusLng,
    this.focusZoom,
  });

  final double? focusLat;
  final double? focusLng;
  final double? focusZoom;

  @override
  State<StationsMapPage> createState() => _StationsMapPageState();
}

class _StationsMapPageState extends State<StationsMapPage> {
  final MapController _mapController = MapController();
  bool _centeredToUserLocationOnce = false;
  bool _canCreateReportFab = true;
  StreamSubscription? _srSub;
  StreamSubscription? _srStateSub; 

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return (jsonDecode(payload) as Map<String, dynamic>);
    } catch (_) { return {}; }
  }

  bool _isBomberoToken(String? token) {
    if (token == null || token.isEmpty) return false;
    final p = _decodeJwt(token);
    final v = p['rol_id'] ?? p['role_id'] ?? p['rolId'] ?? p['roleId'] ?? p['rol'] ?? p['role'];
    if (v == null) return false;
    if (v is num) return v.toInt() == 2;
    final s = v.toString().toUpperCase();
    if (int.tryParse(s) == 2) return true;
    return s.contains('BOMBERO');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasFocus = widget.focusLat != null && widget.focusLng != null;
      if (hasFocus) {
        try {
          _mapController.move(
            LatLng(widget.focusLat!, widget.focusLng!),
            widget.focusZoom ?? 15.5,
          );
        } catch (_) {}
      } else {
        _centerToUserLocationOnce();
      }

      context.read<StationProvider>().loadStations();

      final auth = context.read<AuthProvider>();
      auth.ensureRoleParsed();
      final token = auth.token;

      if (token != null && token.isNotEmpty) {
        final isBombero = _isBomberoToken(token);
        if (mounted) setState(() { _canCreateReportFab = !isBombero; });
        final rp = context.read<ReportProvider>();
        await rp.loadAccepted(token: token);

        try {
          await NotificacionesHub.instance.ensureConnected(
            baseUrl: AppConfig.baseUrl,
            token: token,
          );
        } catch (_) {}
        NotificacionesHub.instance.setReloadAccepted(() async {
          await rp.loadAccepted(token: token);
        });

        NotificacionesHub.instance.setOnReporteMitigado((_) async {
          await rp.loadAccepted(token: token);
        });
        NotificacionesHub.instance.setOnReporteEstado((_, __) async {
          await rp.loadAccepted(token: token);
        });

        if (isBombero) {
          NotificacionesHub.instance.setReloadAccepted(() async {
            await rp.loadAccepted(token: token);
          });
        } else {
          await _srSub?.cancel();
          _srSub = null;
        }
      }
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

  void _openCreateReport() async {
    try { context.read<ReportProvider>().reset(); } catch (_) {}
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateReportSheet(),
    );
    if (ok == true && mounted) {
      final token = context.read<AuthProvider>().token;
      if (token != null && token.isNotEmpty) {
        context.read<ReportProvider>().loadAccepted(token: token);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte enviado')),
      );
    }
  }

  String? _resolvePhotoUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final base = Uri.parse(AppConfig.baseUrl); 
      Uri u = Uri.parse(raw);
      if (!u.hasScheme) {
        final resolved = base.resolveUri(u);
        debugPrint('[IMG] resolved relative -> $resolved');
        return resolved.toString();
      }
      if (u.host == 'localhost' || u.host == '127.0.0.1') {
        final mapped = u.replace(
          scheme: base.scheme,
          host: base.host,
          port: base.hasPort ? base.port : u.port,
        );
        debugPrint('[IMG] mapped localhost -> $mapped');
        return mapped.toString();
      }
      debugPrint('[IMG] raw url (absolute): $u');
      return u.toString();
    } catch (e) {
      debugPrint('[IMG] resolve error: $e');
      final base = AppConfig.baseUrl.replaceAll(RegExp(r'\/$'), '');
      final path = raw.startsWith('/') ? raw : '/$raw';
      return '$base$path';
    }
  }


  int? _getReportId(dynamic r) {
    try {
      return r.id ?? r.reporteId ?? r['id'] ?? r['reporteId'];
    } catch (_) {
      return null;
    }
  }
  int? _pickInt(dynamic o, List<String> keys) {
    try {
      for (final k in keys) {
        final v = (o is Map) ? o[k] : (o as dynamic?)?[k];
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) {
          final n = int.tryParse(v);
          if (n != null) return n;
        }
      }
    } catch (_) {}
    return null;
  }
  String? _pickStr(dynamic o, List<String> keys) {
    try {
      for (final k in keys) {
        final v = (o is Map) ? o[k] : (o as dynamic?)?[k];
        if (v == null) continue;
        return v.toString();
      }
    } catch (_) {}
    return null;
  }

  int? _getAssignedStationId(dynamic r) {
    return _pickInt(r, ['estacionId','EstacionId','idEstacion','IdEstacion','stationId','StationId']);
  }

  int? _stationIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final p = _decodeJwt(token);
    final v = p['estacion_id'] ?? p['estacionId'] ?? p['station_id'] ?? p['stationId'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<void> _mitigarReporte(int id) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'\/$'), '');
    final uri = Uri.parse('$base/api/Bombero/reportes/$id/mitigar');
    debugPrint('[MITIGAR][POST] $uri');
    final res = await http.post(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    debugPrint('[MITIGAR][RES] ${res.statusCode} ${res.reasonPhrase}');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      try { await context.read<ReportProvider>().loadAccepted(token: token); } catch (_) {}
      return;
    }
    throw Exception('HTTP ${res.statusCode} $uri -> ${res.body}');
  }
  Future<Map<String, dynamic>?> _fetchReportDetail(int id) async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) return null;
      final base = AppConfig.baseUrl.replaceAll(RegExp(r'\/$'), '');
      final uri = Uri.parse('$base/api/Usuarios/reportes/$id');
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        return (data is Map<String, dynamic>) ? data : null;
      }
    } catch (_) {}
    return null;
  }

  void _showAcceptedReportInfo(dynamic r) {
    final String? rawUrl = (r.fotoUrl ?? r.foto ?? r.imageUrl)?.toString();
    final String? url = _resolvePhotoUrl(rawUrl);
    final String descripcion = (r.descripcion ?? r.description ?? '').toString();

    final token = context.read<AuthProvider>().token;
    final bool isBombero = _isBomberoToken(token);
    final int? reportId = _getReportId(r);

    int? assignedStationId = _getAssignedStationId(r);
    String estado = (_pickStr(r, ['estado','Estado']) ?? '').toUpperCase();
    final int? myStationId = _stationIdFromToken(token);

    bool requestedDetail = false; 

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: StatefulBuilder(
          builder: (context, setLocal) {
            bool loading = false;
            if (!requestedDetail && reportId != null && (assignedStationId == null || estado.isEmpty)) {
              requestedDetail = true;
              () async {
                final d = await _fetchReportDetail(reportId);
                if (d != null) {
                  setLocal(() {
                    assignedStationId = _pickInt(d, ['estacionId','EstacionId','idEstacion','IdEstacion']);
                    estado = (_pickStr(d, ['estado','Estado']) ?? '').toUpperCase();
                  });
                }
              }();
            }

            final bool canMitigar = isBombero &&
                reportId != null &&
                myStationId != null &&
                assignedStationId != null &&
                estado == 'ACEPTADO' &&
                assignedStationId == myStationId;

            Future<void> onMitigar(dynamic outerCtx) async {
              if (reportId == null) return;
              setLocal(() => loading = true);
              try {
                await _mitigarReporte(reportId);
                if (mounted) Navigator.of(context).pop();
                if (outerCtx.mounted) {
                  ScaffoldMessenger.of(outerCtx).showSnackBar(
                    const SnackBar(content: Text('Reporte mitigado')),
                  );
                }
              } catch (e) {
                if (outerCtx.mounted) {
                  ScaffoldMessenger.of(outerCtx).showSnackBar(
                    SnackBar(content: Text('Error al mitigar: $e')),
                  );
                }
              } finally {
                setLocal(() => loading = false);
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reporte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (url != null && url.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Text('No se pudo cargar la imagen'),
                      ),
                    ),
                  ),
                if ((url ?? '').isNotEmpty) const SizedBox(height: 8),
                Text(descripcion.isEmpty ? 'Sin descripción' : descripcion, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
                if (canMitigar)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: loading ? const Text('Mitigando...') : const Text('Mitigado'),
                      onPressed: loading ? null : () => onMitigar(context),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _srSub?.cancel();
    _srStateSub?.cancel(); 
    try { context.read<ReportProvider>().stopAcceptedAutoRefresh(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StationProvider>(
      builder: (context, sp, _) {
        final rp = context.watch<ReportProvider>();
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

        final incidentMarkers = rp.accepted
            .where((r) => r.lat != null && r.lon != null)
            .map(
              (r) => Marker(
                point: LatLng(r.lat!, r.lon!),
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () => _showAcceptedReportInfo(r),
                  child: const Tooltip(
                    message: 'Incidente aceptado',
                    child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
                  ),
                ),
              ),
            )
            .toList();

        final center = hasData ? LatLng(sp.stations.first.lat, sp.stations.first.lon) : _defaultCenter();

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
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
                  if (incidentMarkers.isNotEmpty) MarkerLayer(markers: incidentMarkers),
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
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(sp.error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                ],
              ),
              if (_canCreateReportFab) 
              Positioned(
                left: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
                child: FloatingActionButton(
                  heroTag: 'fab_report_bottom_left',
                  backgroundColor: Colors.deepOrange,
                  onPressed: _openCreateReport,
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          bottomNavigationBar: const AppBottomNavBar(selectedIndex: 0),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'fit',
                onPressed: () {
                  final allPoints = <LatLng>[];
                  for (final p in polygons) { allPoints.addAll(p.points); }
                  for (final m in markers) { allPoints.add(m.point); }
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
        );
      },
    );
  }
}

class _SingleNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _SingleNavItem({required this.icon, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}