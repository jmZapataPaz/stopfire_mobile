import 'package:stopfire_mobile/features/account/domain/entities/account.dart';
import 'package:stopfire_mobile/features/account/domain/repositories/account_repository.dart';

class GetAccountUseCase {
  final AccountRepository repository;
  GetAccountUseCase(this.repository);

  Future<Account> call(int id) => repository.getById(id);
}