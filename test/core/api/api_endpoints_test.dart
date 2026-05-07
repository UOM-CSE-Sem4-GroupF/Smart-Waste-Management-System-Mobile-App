import 'package:flutter_test/flutter_test.dart';
import 'package:waste_collect_driver/core/api/api_endpoints.dart';

void main() {
  test('ApiEndpoints builds expected paths', () {
    expect(ApiEndpoints.collectionJobs, '/api/v1/collection-jobs');
    expect(ApiEndpoints.jobById('JOB-1'), '/api/v1/collection-jobs/JOB-1');
    expect(ApiEndpoints.acceptJob('JOB-2'), '/api/v1/collection-jobs/JOB-2/accept');
    expect(ApiEndpoints.rejectJob('JOB-3'), '/api/v1/collection-jobs/JOB-3/reject');
    expect(ApiEndpoints.jobProgress('JOB-4'), '/api/v1/jobs/JOB-4/progress');
    expect(ApiEndpoints.collectBin('J1', 'B1'), '/api/v1/collections/J1/bins/B1/collected');
    expect(ApiEndpoints.skipBin('J1', 'B1'), '/api/v1/collections/J1/bins/B1/skip');
    expect(ApiEndpoints.driverStats, '/api/v1/drivers/me/stats');
  });
}
