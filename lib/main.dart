import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/index.dart';

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
  final regRemote = RegisterRemoteDataSource(httpClient);
  final regRepository = RegisterRepositoryImpl(remote: regRemote);
  final startRegUseCase = StartRegistrationUseCase(regRepository);
  final verifyRegUseCase = VerifyRegistrationUseCase(regRepository);

  runApp(MainApp(
    repository: repository,
    loginUseCase: loginUseCase,
    getStationsUseCase: getStationsUseCase,
    getAccountUseCase: getAccountUseCase,
    // NUEVO
    startRegUseCase: startRegUseCase,
    verifyRegUseCase: verifyRegUseCase,
  ));
}

class MainApp extends StatelessWidget {
  final AuthRepositoryImpl repository;
  final LoginUseCase loginUseCase;
  final GetStationsUseCase getStationsUseCase;
  final GetAccountUseCase getAccountUseCase;
  // NUEVO
  final StartRegistrationUseCase startRegUseCase;
  final VerifyRegistrationUseCase verifyRegUseCase;

  const MainApp({
    super.key,
    required this.repository,
    required this.loginUseCase,
    required this.getStationsUseCase,
    required this.getAccountUseCase,
    // NUEVO
    required this.startRegUseCase,
    required this.verifyRegUseCase,
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
        ChangeNotifierProvider(
          create: (_) => RegisterProvider(
            startUseCase: startRegUseCase,
            verifyUseCase: verifyRegUseCase,
          ),
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
