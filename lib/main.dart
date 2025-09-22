import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/core/network/http_client.dart';
import 'package:stopfire_mobile/core/storage/token_storage.dart';
import 'package:stopfire_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:stopfire_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:stopfire_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:stopfire_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/auth_provider.dart';
import 'package:stopfire_mobile/features/stations/data/datasources/station_remote_data_source.dart';
import 'package:stopfire_mobile/features/stations/data/repositories/station_repository_impl.dart';
import 'package:stopfire_mobile/features/stations/domain/usecases/get_stations_usecase.dart';
import 'package:stopfire_mobile/features/stations/presentation/pages/stations_map_page.dart';
import 'package:stopfire_mobile/features/stations/presentation/state/station_provider.dart';
import 'package:stopfire_mobile/features/account/data/datasources/account_remote_data_source.dart';
import 'package:stopfire_mobile/features/account/data/repositories/account_repository_impl.dart';
import 'package:stopfire_mobile/features/account/domain/usecases/get_account_usecase.dart';
import 'package:stopfire_mobile/features/account/presentation/state/account_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final httpClient = AppHttpClient();
  final remote = AuthRemoteDataSource(httpClient);
  final storage = SecureTokenStorage();
  final repository = AuthRepositoryImpl(remote: remote, storage: storage);
  final loginUseCase = LoginUseCase(repository);
  final stationRemote = StationRemoteDataSource(httpClient);
  final stationRepository = StationRepositoryImpl(remote: stationRemote);
  final getStationsUseCase = GetStationsUseCase(stationRepository);
  final accountRemote = AccountRemoteDataSource(httpClient);
  final accountRepository = AccountRepositoryImpl(remote: accountRemote);
  final getAccountUseCase = GetAccountUseCase(accountRepository);

  runApp(MainApp(
    repository: repository,
    loginUseCase: loginUseCase,
    getStationsUseCase: getStationsUseCase,
    getAccountUseCase: getAccountUseCase,
  ));
}

class MainApp extends StatelessWidget {
  final AuthRepositoryImpl repository;
  final LoginUseCase loginUseCase;
  final GetStationsUseCase getStationsUseCase;
  final GetAccountUseCase getAccountUseCase;

  const MainApp({
    super.key,
    required this.repository,
    required this.loginUseCase,
    required this.getStationsUseCase,
    required this.getAccountUseCase, 
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(loginUseCase: loginUseCase, repository: repository),
        ),
        ChangeNotifierProvider(
          create: (_) => StationProvider(getStationsUseCase: getStationsUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => AccountProvider(getAccountUseCase: getAccountUseCase),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: const _SplashGate(),
      ),
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  late Future<void> _init;

  @override
  void initState() {
    super.initState();
    _init = context.read<AuthProvider>().loadInitialSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final hasToken = context.read<AuthProvider>().token != null;
        return hasToken ? const StationsMapPage() : const LoginPage();
      },
    );
  }
}
