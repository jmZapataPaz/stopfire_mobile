import 'package:stopfire_mobile/features/stations/domain/entities/station.dart';
import 'package:stopfire_mobile/features/stations/domain/repositories/station_repository.dart';

class GetStationsUseCase {
  final StationRepository repository;
  GetStationsUseCase(this.repository);

  Future<List<Station>> call() => repository.getStations();
}