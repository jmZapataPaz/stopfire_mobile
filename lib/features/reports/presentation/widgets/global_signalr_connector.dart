import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/core/navigation/app_navigator.dart';
import 'package:stopfire_mobile/core/signalr/notificaciones_hub.dart';
import 'package:stopfire_mobile/features/reports/presentation/services/incoming_report_handler.dart';
import 'package:stopfire_mobile/features/reports/presentation/state/report_provider.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/auth_provider.dart';
import 'package:stopfire_mobile/core/config/app_config.dart';

class GlobalSignalRConnector extends StatefulWidget {
  final Widget child;
  const GlobalSignalRConnector({super.key, required this.child});

  @override
  State<GlobalSignalRConnector> createState() => _GlobalSignalRConnectorState();
}

class _GlobalSignalRConnectorState extends State<GlobalSignalRConnector> with WidgetsBindingObserver {
  StreamSubscription<IncomingReport>? _sub;
  String? _lastToken;
  final Set<int> _shownIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureConnected();
    }
  }

  bool _isBomberoToken(String? token) {
    if (token == null || token.isEmpty) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final p = (jsonDecode(payload) as Map<String, dynamic>);
      final v = p['rol_id'] ?? p['role_id'] ?? p['rolId'] ?? p['roleId'] ?? p['rol'] ?? p['role'];
      if (v is num) return v.toInt() == 2;
      final s = v.toString().toUpperCase();
      if (int.tryParse(s) == 2) return true;
      return s.contains('BOMBERO');
    } catch (_) { return false; }
  }

  Future<void> _ensureConnected() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final isBombero = _isBomberoToken(token);
    if (!isBombero) {
      await _sub?.cancel();
      _sub = null;
      return;
    }

    final apiBase = AppConfig.baseUrl;
    await NotificacionesHub.instance.ensureConnected(baseUrl: apiBase, token: token!);

    _sub ??= NotificacionesHub.instance.incomingReports.listen((r) async {
      if (_shownIds.contains(r.id)) return;
      _shownIds.add(r.id);

      final handler = IncomingReportHandler(
        navigatorKey: appNavigatorKey,
        apiBase: apiBase,
        tokenProvider: () async => context.read<AuthProvider>().token,
      );
      final result = await handler.showIncoming(r); 
      try {
        await context.read<ReportProvider>().loadAccepted(token: auth.token!);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = context.select<AuthProvider, String?>((p) => p.token);
    if (token != _lastToken) {
      _lastToken = token;
      if (token?.isNotEmpty == true) {
        _ensureConnected();
      } else {
        _sub?.cancel();
        _sub = null;
      }
    }
    return widget.child;
  }
}