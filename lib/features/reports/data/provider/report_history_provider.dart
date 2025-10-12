import 'package:flutter/material.dart';
import '../../domain/entities/report_history.dart';
import '../../data/datasources/report_history_remote_data_source.dart';

class ReportHistoryProvider extends ChangeNotifier {
  final _ds = ReportHistoryRemoteDataSource();
  List<ReportHistory> items = [];
  bool loading = false;
  String? error;

  Future<void> load(int idEstacion, String token) async {
    loading = true; error = null; notifyListeners();
    try {
      items = await _ds.fetchHistorial(idEstacion, token);
    } catch (e) {
      error = e.toString();
    }
    loading = false; notifyListeners();
  }
}