import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stopfire_mobile/features/reports/domain/entities/report.dart';
import 'package:stopfire_mobile/features/reports/domain/usecases/create_report_usecase.dart';
import 'package:stopfire_mobile/features/reports/domain/usecases/get_accepted_reports_usecase.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ReportProvider extends ChangeNotifier {
  final CreateReportUseCase createReportUseCase;
  final GetAcceptedReportsUseCase? getAcceptedReportsUseCase;

  ReportProvider({
    required this.createReportUseCase,
    this.getAcceptedReportsUseCase,
  });

  File? _photo;
  String _descripcion = '';
  bool _sending = false;
  String? _error;

  // aceptados
  List<Report> _accepted = [];
  bool _loadingAccepted = false;
  Timer? _acceptedTimer;

  File? get photo => _photo;
  List<Report> get accepted => _accepted;
  bool get loadingAccepted => _loadingAccepted;

  String? get error => _error;
  bool get sending => _sending;

  set descripcionSetter(String v) {
    _descripcion = v;
    notifyListeners();
  }

  Future<void> takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      final raw = File(image.path);
      _photo = await _asJpeg(raw);
      print('[REPORT] Foto tomada: ${_photo!.path}');
      notifyListeners();
    }
  }

  Future<File> _asJpeg(File source) async {
    try {
      final bytes = await source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return source;
      final jpg = img.encodeJpg(decoded, quality: 85);
      final dir = await getTemporaryDirectory();
      final outPath = p.join(dir.path, 'reporte_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final out = File(outPath);
      await out.writeAsBytes(jpg, flush: true);
      return out;
    } catch (_) {
      return source;
    }
  }

  Future<void> submit({required String token}) async {
    _error = null;
    if (_photo == null) {
      _error = 'La foto es obligatoria';
      print('[REPORT] Error: foto obligatoria ausente');
      notifyListeners();
      return;
    }
    _sending = true;
    notifyListeners();
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final lat = pos.latitude.toString();
      final lng = pos.longitude.toString();
      final sizeBytes = await _photo!.length();
      print('[REPORT] Enviando -> lat=$lat lng=$lng desc="${_descripcion}" file=${_photo!.path} (${(sizeBytes/1024).toStringAsFixed(1)} KB)');

      await createReportUseCase(
        token: token,
        descripcion: _descripcion,
        lat: lat,
        lng: lng,
        photo: _photo!,
      );
      unawaited(Future(() => loadAccepted(token: token)));
      print('[REPORT] Enviado OK');
    } catch (e) {
      _error = e.toString();
      print('[REPORT] Error envío: $_error');
      rethrow;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> loadAccepted({required String token}) async {
    if (getAcceptedReportsUseCase == null) return;
    _loadingAccepted = true;
    notifyListeners();
    try {
      final items = await getAcceptedReportsUseCase!.call(token: token);
      _accepted = items;
      print('[REPORT][LIST] aceptados=${items.length}');
    } catch (e) {
      print('[REPORT][LIST] error: $e');
    } finally {
      _loadingAccepted = false;
      notifyListeners();
    }
  }

  void startAcceptedAutoRefresh({required String token, Duration interval = const Duration(seconds: 30)}) {
    _acceptedTimer?.cancel();
    _acceptedTimer = Timer.periodic(interval, (_) {
      loadAccepted(token: token);
    });
    print('[REPORT][LIST] auto refresh cada ${interval.inSeconds}s');
  }

  void stopAcceptedAutoRefresh() {
    _acceptedTimer?.cancel();
    _acceptedTimer = null;
  }

  void reset() {
    _photo = null;
    _descripcion = '';
    _sending = false;
    _error = null;
    notifyListeners();
  }

  void removeAcceptedById(int id) {
    final before = _accepted.length;
    _accepted = _accepted.where((r) => r.id != id).toList();
    if (_accepted.length != before) {
      notifyListeners();
      print('[REPORT][LIST] removido por mitigación id=$id, quedan=${_accepted.length}');
    }
  }
}