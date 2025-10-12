import 'package:flutter/foundation.dart';
import 'package:stopfire_mobile/features/stations/data/usuario_estaciones_service.dart';

class CitizenStationsProvider extends ChangeNotifier {
  List<UsuarioEstacion> estaciones = [];
  bool loading = false;
  String? error;

  Future<void> load({String? token}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      estaciones = await UsuarioEstacionesService.getAll(token: token);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}