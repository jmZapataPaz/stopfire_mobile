import 'package:stopfire_mobile/core/storage/token_storage.dart';
import 'package:stopfire_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:stopfire_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final TokenStorage storage;

  AuthRepositoryImpl({required this.remote, required this.storage});

  @override
  Future<String> login({required String correo, required String contrasena}) async {
    final token = await remote.login(correo: correo, contrasena: contrasena);
    await storage.saveToken(token);
    return token;
  }

  @override
  Future<String?> getSavedToken() => storage.readToken();

  @override
  Future<void> logout() => storage.clearToken();
}