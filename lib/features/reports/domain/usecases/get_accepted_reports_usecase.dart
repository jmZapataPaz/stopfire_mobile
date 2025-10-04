import 'package:stopfire_mobile/features/reports/domain/entities/report.dart';
import 'package:stopfire_mobile/features/reports/domain/repositories/report_repository.dart';

class GetAcceptedReportsUseCase {
  final ReportRepository repository;
  GetAcceptedReportsUseCase(this.repository);

  Future<List<Report>> call({required String token}) => repository.getAccepted(token: token);
}