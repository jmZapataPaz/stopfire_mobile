import 'package:stopfire_mobile/features/register/data/datasources/register_remote_data_source.dart';
import 'package:stopfire_mobile/features/register/domain/repositories/register_repository.dart';

class RegisterRepositoryImpl implements RegisterRepository {
  final RegisterRemoteDataSource remote;
  RegisterRepositoryImpl({required this.remote});

  @override
  Future<void> start({
    required String nombre,
    required String apellido,
    required String ci,
    required String correo,
    required String celular,
    required String contrasena,
  }) {
    return remote.start(
      nombre: nombre,
      apellido: apellido,
      ci: ci,
      correo: correo,
      celular: celular,
      contrasena: contrasena,
    );
  }

  @override
  Future<void> verify({required String correo, required String codigo}) {
    return remote.verify(correo: correo, codigo: codigo);
  }
}