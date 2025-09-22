import 'package:stopfire_mobile/core/config/app_config.dart';
import 'package:stopfire_mobile/core/network/http_client.dart';
import 'package:stopfire_mobile/features/stations/data/models/station_model.dart';

class StationRemoteDataSource {
  final AppHttpClient httpClient;
  StationRemoteDataSource(this.httpClient);

  Future<List<StationModel>> fetchStations() async {
    final url = '${AppConfig.baseUrl}${AppConfig.stationsEndpoint}';
    final data = await httpClient.getJson(url);
    if (data is List) {
      return data.map((e) => StationModel.fromJson(e as Map<String, dynamic>)).toList();
    } else if (data is Map<String, dynamic>) {
      return [StationModel.fromJson(data)];
    }
    return [];
  }
}