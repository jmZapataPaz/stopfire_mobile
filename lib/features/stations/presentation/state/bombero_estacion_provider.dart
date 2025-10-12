import 'package:flutter/foundation.dart';
import 'package:stopfire_mobile/features/stations/data/estacion_service.dart';

class BomberoEstacionProvider extends ChangeNotifier {
  BomberoEstacionProvider({required this.token});
  final String token;

  EstacionDetalle? estacion;
  bool loading = false;
  bool saving = false;
  String? error;
  bool editMode = false;

  String nombre = '';
  String descripcionDireccion = '';
  String celular = '';

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final d = await EstacionService.getDetalle(token);
      estacion = d;
      nombre = d.nombre ?? '';
      descripcionDireccion = d.descripcionDireccion ?? '';
      celular = d.celular ?? '';
    } catch (e) {
      error = e.toString(); 
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void toggleEdit() {
    editMode = !editMode;
    if (!editMode && estacion != null) {
      nombre = estacion!.nombre ?? '';
      descripcionDireccion = estacion!.descripcionDireccion ?? '';
      celular = estacion!.celular ?? '';
    }
    notifyListeners();
  }

  Future<bool> save() async {
    if (estacion == null) return false;
    final cambios = <String, dynamic>{};
    if ((nombre) != (estacion!.nombre ?? '')) cambios['nombre'] = nombre;
    if ((descripcionDireccion) != (estacion!.descripcionDireccion ?? '')) cambios['descripcionDireccion'] = descripcionDireccion;
    if ((celular) != (estacion!.celular ?? '')) cambios['celular'] = celular;

    if (cambios.isEmpty) {
      editMode = false;
      notifyListeners();
      return true;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      final upd = await EstacionService.actualizar(token, estacion!.id, cambios);
      estacion = upd;
      nombre = upd.nombre ?? '';
      descripcionDireccion = upd.descripcionDireccion ?? '';
      celular = upd.celular ?? '';
      editMode = false;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}