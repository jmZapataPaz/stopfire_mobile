import 'dart:io';
import 'package:stopfire_mobile/features/reports/domain/repositories/report_repository.dart';

class CreateReportUseCase {
  final ReportRepository repository;
  CreateReportUseCase(this.repository);

  Future<void> call({
    required String token,
    required String descripcion,
    required String lat,
    required String lng,
    required File photo,
  }) => repository.create(
        token: token,
        descripcion: descripcion,
        lat: lat,
        lng: lng,
        photo: photo,
      );
}