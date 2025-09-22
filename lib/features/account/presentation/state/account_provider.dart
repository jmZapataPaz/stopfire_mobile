import 'package:flutter/foundation.dart';
import 'package:stopfire_mobile/core/utils/jwt_decoder.dart';
import 'package:stopfire_mobile/features/account/domain/entities/account.dart';
import 'package:stopfire_mobile/features/account/domain/usecases/get_account_usecase.dart';

class AccountProvider extends ChangeNotifier {
  final GetAccountUseCase getAccountUseCase;

  AccountProvider({required this.getAccountUseCase});

  Account? _account;
  bool _loading = false;
  String? _error;

  Account? get account => _account;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadFromToken(String token) async {
    final id = JwtDecoder.getUserIdFromSub(token);
    if (id == null) {
      _error = 'Token inválido';
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _account = await getAccountUseCase(id);
    } catch (e) {
      _error = e.toString();
      _account = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _account = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}