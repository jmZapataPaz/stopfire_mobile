import 'package:stopfire_mobile/features/auth/data/datasources/password_recover_remote_data_source.dart';
import 'package:stopfire_mobile/features/auth/domain/repositories/password_recover_repository.dart';

class PasswordRecoverRepositoryImpl implements PasswordRecoverRepository {
  final PasswordRecoverRemoteDataSource remote;
  PasswordRecoverRepositoryImpl({required this.remote});

  @override
  Future<void> iniciar(String correo) => remote.iniciar(correo: correo);

  @override
  Future<void> verificar(String correo, String codigo, String nuevaContrasena) =>
      remote.verificar(correo: correo, codigo: codigo, nuevaContrasena: nuevaContrasena);
}