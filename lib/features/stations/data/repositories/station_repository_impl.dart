import 'package:stopfire_mobile/features/stations/data/datasources/station_remote_data_source.dart';
import 'package:stopfire_mobile/features/stations/domain/entities/station.dart';
import 'package:stopfire_mobile/features/stations/domain/repositories/station_repository.dart';

class StationRepositoryImpl implements StationRepository {
  final StationRemoteDataSource remote;
  StationRepositoryImpl({required this.remote});

  @override
  Future<List<Station>> getStations() async {
    final models = await remote.fetchStations();
    return models.map((m) => m.toEntity()).toList();
  }
}