import 'dart:io';
import 'package:stopfire_mobile/features/reports/domain/entities/report.dart';

abstract class ReportRepository {
  Future<void> create({
    required String token,
    required String descripcion,
    required String lat,
    required String lng,
    required File photo,
  });

  Future<List<Report>> getAccepted({required String token});
}