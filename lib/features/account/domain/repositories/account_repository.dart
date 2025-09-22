import 'package:stopfire_mobile/features/account/domain/entities/account.dart';

abstract class AccountRepository {
  Future<Account> getById(int id);
}