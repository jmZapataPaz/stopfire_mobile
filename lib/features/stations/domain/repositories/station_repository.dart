import 'package:stopfire_mobile/features/stations/domain/entities/station.dart';

abstract class StationRepository {
  Future<List<Station>> getStations();
}