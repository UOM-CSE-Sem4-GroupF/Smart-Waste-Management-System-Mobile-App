class ApiEndpoints {
  ApiEndpoints._();

  // Jobs
  static const collectionJobs = '/api/v1/collection-jobs';
  static String jobById(String id) => '/api/v1/collection-jobs/$id';
  static String acceptJob(String id) =>
      '/api/v1/collection-jobs/$id/accept';
  static String rejectJob(String id) =>
      '/api/v1/collection-jobs/$id/reject';
  static String jobProgress(String id) => '/api/v1/jobs/$id/progress';
  static String updateStopStatus(String jobId, String clusterId) =>
      '/api/v1/collection-jobs/$jobId/stops/$clusterId/status';

  // Bin actions
  static String collectBin(String jobId, String binId) =>
      '/api/v1/collections/$jobId/bins/$binId/collected';
  static String skipBin(String jobId, String binId) =>
      '/api/v1/collections/$jobId/bins/$binId/skip';

  // Driver
  static const fcmToken = '/api/v1/drivers/fcm-token';
  static const driverStats = '/api/v1/drivers/me/stats';
}
