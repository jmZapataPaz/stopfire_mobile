import 'dart:io';
import 'package:stopfire_mobile/features/reports/data/datasources/report_remote_data_source.dart';
import 'package:stopfire_mobile/features/reports/data/models/report_model.dart';
import 'package:stopfire_mobile/features/reports/domain/entities/report.dart';
import 'package:stopfire_mobile/features/reports/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remote;
  ReportRepositoryImpl({required this.remote});

  @override
  Future<void> create({
    required String token,
    required String descripcion,
    required String lat,
    required String lng,
    required File photo,
  }) {
    return remote.createReport(
      token: token,
      descripcion: descripcion,
      lat: lat,
      lng: lng,
      photo: photo,
    );
  }

  @override
  Future<List<Report>> getAccepted({required String token}) async {
    final all = await remote.getReports(token: token);
    return all
        .where((r) => (r.estado ?? '').toUpperCase() == 'ACEPTADO' && r.latitud != null && r.longitud != null)
        .map((ReportModel r) => Report(
              id: r.id,
              descripcion: r.descripcion,
              fotoUrl: r.fotoUrl,
              lat: r.latitud,
              lon: r.longitud,
              estado: r.estado,
            ))
        .toList();
  }
}