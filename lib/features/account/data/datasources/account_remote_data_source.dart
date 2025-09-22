import 'package:stopfire_mobile/core/config/app_config.dart';
import 'package:stopfire_mobile/core/network/http_client.dart';
import 'package:stopfire_mobile/features/account/data/models/account_model.dart';

class AccountRemoteDataSource {
  final AppHttpClient httpClient;
  AccountRemoteDataSource(this.httpClient);

  Future<AccountModel> fetchById(int id) async {
    final url = '${AppConfig.baseUrl}/api/Usuarios/$id';
    final data = await httpClient.getJson(url);
    if (data is Map<String, dynamic>) {
      return AccountModel.fromJson(data);
    }
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return AccountModel.fromJson(data.first as Map<String, dynamic>);
    }
    throw HttpFailure('Respuesta inválida de cuenta');
  }
}