import 'package:stopfire_mobile/features/account/data/datasources/account_remote_data_source.dart';
import 'package:stopfire_mobile/features/account/domain/entities/account.dart';
import 'package:stopfire_mobile/features/account/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remote;
  AccountRepositoryImpl({required this.remote});

  @override
  Future<Account> getById(int id) async {
    final model = await remote.fetchById(id);
    return model.toEntity();
  }
}