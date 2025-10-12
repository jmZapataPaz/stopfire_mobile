import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/index.dart';
import 'package:stopfire_mobile/core/navigation/app_navigator.dart';
import 'package:stopfire_mobile/core/signalr/notificaciones_hub.dart';
import 'package:stopfire_mobile/features/reports/data/datasources/report_remote_data_source.dart';
import 'package:stopfire_mobile/features/reports/data/repositories/report_repository_impl.dart';
import 'package:stopfire_mobile/features/reports/domain/usecases/create_report_usecase.dart';
import 'package:stopfire_mobile/features/reports/domain/usecases/get_accepted_reports_usecase.dart';
import 'package:stopfire_mobile/features/reports/presentation/services/incoming_report_handler.dart';
import 'package:stopfire_mobile/features/reports/presentation/state/report_provider.dart';
import 'package:stopfire_mobile/features/reports/presentation/widgets/global_signalr_connector.dart';
import 'package:stopfire_mobile/core/config/app_config.dart'; // NUEVO

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
  final reportRemote = ReportRemoteDataSource();
  final reportRepository = ReportRepositoryImpl(remote: reportRemote);
  final createReportUseCase = CreateReportUseCase(reportRepository);
  final getAcceptedReportsUseCase = GetAcceptedReportsUseCase(reportRepository);

  runApp(MainApp(
    repository: repository,
    loginUseCase: loginUseCase,
    getStationsUseCase: getStationsUseCase,
    getAccountUseCase: getAccountUseCase,
    startRegUseCase: startRegUseCase,
    verifyRegUseCase: verifyRegUseCase,
    createReportUseCase: createReportUseCase,
    getAcceptedReportsUseCase: getAcceptedReportsUseCase,
  ));
}

class MainApp extends StatelessWidget {
  final AuthRepositoryImpl repository;
  final LoginUseCase loginUseCase;
  final GetStationsUseCase getStationsUseCase;
  final GetAccountUseCase getAccountUseCase;
  final StartRegistrationUseCase startRegUseCase;
  final VerifyRegistrationUseCase verifyRegUseCase;
  final CreateReportUseCase createReportUseCase;
  final GetAcceptedReportsUseCase getAcceptedReportsUseCase;

  const MainApp({
    super.key,
    required this.repository,
    required this.loginUseCase,
    required this.getStationsUseCase,
    required this.getAccountUseCase,
    required this.startRegUseCase,
    required this.verifyRegUseCase,
    required this.createReportUseCase,
    required this.getAcceptedReportsUseCase,
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
        ChangeNotifierProvider(
          create: (_) => ReportProvider(
            createReportUseCase: createReportUseCase,
            getAcceptedReportsUseCase: getAcceptedReportsUseCase,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        navigatorKey: appNavigatorKey,
        builder: (context, child) => GlobalSignalRConnector(child: child!),
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final hasToken = context.read<AuthProvider>().token != null;
        return hasToken ? const StationsMapPage() : const LoginPage();
      },
    );
  }
}
