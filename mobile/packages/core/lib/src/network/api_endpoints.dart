class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login = '/api/v1/auth/login/';
  static const register = '/api/v1/auth/register/';
  static const tokenRefresh = '/api/v1/auth/token/refresh/';
  static const profile = '/api/v1/auth/profile/';
  static const vehicles = '/api/v1/auth/vehicles/';
  static const guards = '/api/v1/auth/guards/';
  static String guard(String id) => '/api/v1/auth/guards/$id/';
  static const notifications = '/api/v1/auth/notifications/';
  static String notificationRead(String id) =>
      '/api/v1/auth/notifications/$id/read/';
  static String vehicleDelete(String id) => '/api/v1/auth/vehicles/$id/';

  // Societies
  static const societies = '/api/v1/societies/';
  static const societiesGeocode = '/api/v1/societies/geocode/';
  static String society(String id) => '/api/v1/societies/$id/';
  static String societySlots(String societyId) =>
      '/api/v1/societies/$societyId/slots/';
  static String slot(String societyId, String slotId) =>
      '/api/v1/societies/$societyId/slots/$slotId/';
  static String slotDecision(String societyId, String slotId) =>
      '/api/v1/societies/$societyId/slots/$slotId/decision/';
  static String slotBlock(String societyId, String slotId) =>
      '/api/v1/societies/$societyId/slots/$slotId/block/';
  static String slotUnblock(String societyId, String slotId) =>
      '/api/v1/societies/$societyId/slots/$slotId/unblock/';
  static String slotAvailability(String societyId, String slotId) =>
      '/api/v1/societies/$societyId/slots/$slotId/availability/';
  static String societyJoinRequests(String societyId) =>
      '/api/v1/societies/$societyId/join-requests/';
  static String societyJoinRequestDecision(String societyId, String requestId) =>
      '/api/v1/societies/$societyId/join-requests/$requestId/decision/';

  // Bookings
  static const bookings = '/api/v1/bookings/';
  static const bookingsList = '/api/v1/bookings/list/';
  static String booking(String id) => '/api/v1/bookings/$id/';
  static String bookingCancel(String id) => '/api/v1/bookings/$id/cancel/';
  static String bookingQr(String id) => '/api/v1/bookings/$id/qr/';

  // Payments
  static const paymentInitiate = '/api/v1/payments/initiate/';
  static const paymentVerify = '/api/v1/payments/verify/';

  // QR Validation
  static const qrEntry = '/api/v1/qr/entry/';
  static const qrExit = '/api/v1/qr/exit/';

  // Penalties
  static const penalties = '/api/v1/penalties/';
  static String penaltyPay(String id) => '/api/v1/penalties/$id/pay/';

  // Admin
  static const adminDashboard = '/api/v1/admin/dashboard/';
  static String adminSocietyStats(String id) =>
      '/api/v1/admin/societies/$id/stats/';
}
