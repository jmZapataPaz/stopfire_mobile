import 'package:flutter/foundation.dart';
import 'package:stopfire_mobile/features/stations/domain/entities/station.dart';
import 'package:stopfire_mobile/features/stations/domain/usecases/get_stations_usecase.dart';

class StationProvider extends ChangeNotifier {
  final GetStationsUseCase getStationsUseCase;

  StationProvider({required this.getStationsUseCase});

  List<Station> _stations = [];
  bool _loading = false;
  String? _error;

  List<Station> get stations => _stations;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadStations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _stations = await getStationsUseCase();
    } catch (e) {
      _error = e.toString();
      _stations = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}