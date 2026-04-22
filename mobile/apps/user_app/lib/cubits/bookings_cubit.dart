import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class BookingsState {
  final bool isLoading;
  final List<BookingModel> bookings;
  final String? error;
  final String statusFilter;

  const BookingsState({
    this.isLoading = false,
    this.bookings = const [],
    this.error,
    this.statusFilter = 'all',
  });

  BookingsState copyWith({
    bool? isLoading,
    List<BookingModel>? bookings,
    String? error,
    String? statusFilter,
  }) {
    return BookingsState(
      isLoading: isLoading ?? this.isLoading,
      bookings: bookings ?? this.bookings,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<BookingModel> get filteredBookings {
    if (statusFilter == 'all') return bookings;
    return bookings.where((b) => b.status == statusFilter).toList();
  }
}

class BookingsCubit extends Cubit<BookingsState> {
  final ApiClient _apiClient;

  BookingsCubit(this._apiClient) : super(const BookingsState());

  Future<void> loadBookings() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await _apiClient.get(ApiEndpoints.bookingsList);
      final data = response.data as Map<String, dynamic>;
      final apiResponse = ApiResponse<BookingModel>.fromJson(
        data,
        (json) => BookingModel.fromJson(json),
      );
      emit(state.copyWith(isLoading: false, bookings: apiResponse.results));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setFilter(String filter) {
    emit(state.copyWith(statusFilter: filter));
  }
}

class BookingDetailState {
  final bool isLoading;
  final BookingModel? booking;
  final String? error;
  final bool isCancelling;
  final bool isInitiatingPayment;

  const BookingDetailState({
    this.isLoading = false,
    this.booking,
    this.error,
    this.isCancelling = false,
    this.isInitiatingPayment = false,
  });

  BookingDetailState copyWith({
    bool? isLoading,
    BookingModel? booking,
    String? error,
    bool? isCancelling,
    bool? isInitiatingPayment,
  }) {
    return BookingDetailState(
      isLoading: isLoading ?? this.isLoading,
      booking: booking ?? this.booking,
      error: error,
      isCancelling: isCancelling ?? this.isCancelling,
      isInitiatingPayment: isInitiatingPayment ?? this.isInitiatingPayment,
    );
  }
}

class BookingDetailCubit extends Cubit<BookingDetailState> {
  final ApiClient _apiClient;

  BookingDetailCubit(this._apiClient) : super(const BookingDetailState());

  Future<void> loadBooking(String id) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await _apiClient.get(ApiEndpoints.booking(id));
      final booking = BookingModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      emit(state.copyWith(isLoading: false, booking: booking));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> cancelBooking(String id) async {
    emit(state.copyWith(isCancelling: true, error: null));
    try {
      await _apiClient.post(ApiEndpoints.bookingCancel(id));
      await loadBooking(id);
      emit(state.copyWith(isCancelling: false));
    } on ApiException catch (e) {
      emit(state.copyWith(isCancelling: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isCancelling: false, error: e.toString()));
    }
  }

  Future<PaymentModel?> initiatePayment(String bookingId) async {
    emit(state.copyWith(isInitiatingPayment: true, error: null));
    try {
      final response = await _apiClient.post(
        ApiEndpoints.paymentInitiate,
        data: {'booking_id': bookingId},
      );
      emit(state.copyWith(isInitiatingPayment: false));
      return PaymentModel.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      emit(state.copyWith(isInitiatingPayment: false, error: e.message));
      return null;
    } catch (e) {
      emit(state.copyWith(isInitiatingPayment: false, error: e.toString()));
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      await _apiClient.post(
        ApiEndpoints.paymentVerify,
        data: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

class BookingCreateState {
  final bool isLoading;
  final SlotModel? slot;
  final SocietyModel? society;
  final List<VehicleModel> vehicles;
  final String? selectedVehicleId;
  final DateTime? startDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool hasPresetWindow;
  final String? error;
  final bool isCreating;
  final BookingModel? createdBooking;

  const BookingCreateState({
    this.isLoading = false,
    this.slot,
    this.society,
    this.vehicles = const [],
    this.selectedVehicleId,
    this.startDate,
    this.startTime,
    this.endTime,
    this.hasPresetWindow = false,
    this.error,
    this.isCreating = false,
    this.createdBooking,
  });

  BookingCreateState copyWith({
    bool? isLoading,
    SlotModel? slot,
    SocietyModel? society,
    List<VehicleModel>? vehicles,
    String? selectedVehicleId,
    DateTime? startDate,
    DateTime? startTime,
    DateTime? endTime,
    bool? hasPresetWindow,
    String? error,
    bool? isCreating,
    BookingModel? createdBooking,
  }) {
    return BookingCreateState(
      isLoading: isLoading ?? this.isLoading,
      slot: slot ?? this.slot,
      society: society ?? this.society,
      vehicles: vehicles ?? this.vehicles,
      selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hasPresetWindow: hasPresetWindow ?? this.hasPresetWindow,
      error: error,
      isCreating: isCreating ?? this.isCreating,
      createdBooking: createdBooking ?? this.createdBooking,
    );
  }

  double? get estimatedAmount {
    if (slot == null || startTime == null || endTime == null) return null;
    final rate = double.tryParse(slot!.hourlyRate) ?? 0;
    final duration = endTime!.difference(startTime!);
    final hours = duration.inMinutes / 60.0;
    if (hours <= 0) return null;
    return rate * hours;
  }
}

class BookingCreateCubit extends Cubit<BookingCreateState> {
  final ApiClient _apiClient;

  BookingCreateCubit(this._apiClient) : super(const BookingCreateState());

  Future<void> initialize({
    required String societyId,
    required String slotId,
    String? bookingDate,
    String? startTime,
    String? endTime,
  }) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final slotResponse = await _apiClient.get(
        ApiEndpoints.slot(societyId, slotId),
      );
      final slot = SlotModel.fromJson(
        slotResponse.data as Map<String, dynamic>,
      );

      final societyResponse = await _apiClient.get(
        ApiEndpoints.society(societyId),
      );
      final society = SocietyModel.fromJson(
        societyResponse.data as Map<String, dynamic>,
      );

      final vehiclesResponse = await _apiClient.get(ApiEndpoints.vehicles);
      List<VehicleModel> vehicles = [];
      final vehiclesData = vehiclesResponse.data;
      if (vehiclesData is Map<String, dynamic> &&
          vehiclesData.containsKey('results')) {
        final apiResp = ApiResponse<VehicleModel>.fromJson(
          vehiclesData,
          (json) => VehicleModel.fromJson(json),
        );
        vehicles = apiResp.results;
      } else if (vehiclesData is List) {
        vehicles = vehiclesData
            .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final activeVehicles = vehicles
          .where(
            (vehicle) =>
                vehicle.isActive && vehicle.vehicleType == slot.slotType,
          )
          .toList();
      final presetStart = _parsePresetDateTime(bookingDate, startTime);
      final presetEnd = _parsePresetDateTime(bookingDate, endTime);
      final now = DateTime.now();
      final defaultDate = DateTime(now.year, now.month, now.day);
      final defaultStart = DateTime(now.year, now.month, now.day, now.hour + 1);
      final defaultEnd = DateTime(now.year, now.month, now.day, now.hour + 2);

      emit(
        state.copyWith(
          isLoading: false,
          slot: slot,
          society: society,
          vehicles: activeVehicles,
          selectedVehicleId: activeVehicles.isNotEmpty
              ? activeVehicles.first.id
              : null,
          startDate: presetStart != null
              ? DateTime(presetStart.year, presetStart.month, presetStart.day)
              : defaultDate,
          startTime: presetStart ?? defaultStart,
          endTime: presetEnd ?? defaultEnd,
          hasPresetWindow: presetStart != null && presetEnd != null,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void selectVehicle(String vehicleId) {
    emit(state.copyWith(selectedVehicleId: vehicleId));
  }

  void setStartDate(DateTime date) {
    emit(state.copyWith(startDate: date));
  }

  void setStartTime(DateTime time) {
    emit(state.copyWith(startTime: time));
  }

  void setEndTime(DateTime time) {
    emit(state.copyWith(endTime: time));
  }

  Future<void> createBooking() async {
    if (state.selectedVehicleId == null) {
      emit(state.copyWith(error: 'Please select a vehicle'));
      return;
    }
    if (state.startTime == null || state.endTime == null) {
      emit(state.copyWith(error: 'Please select start and end time'));
      return;
    }
    if (state.endTime!.isBefore(state.startTime!) ||
        state.endTime!.isAtSameMomentAs(state.startTime!)) {
      emit(state.copyWith(error: 'End time must be after start time'));
      return;
    }

    emit(state.copyWith(isCreating: true, error: null));
    try {
      final startDate = state.startDate ?? DateTime.now();
      final startDt = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        state.startTime!.hour,
        state.startTime!.minute,
      );
      final endDt = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        state.endTime!.hour,
        state.endTime!.minute,
      );

      final response = await _apiClient.post(
        ApiEndpoints.bookings,
        data: {
          'slot_id': state.slot!.id,
          'vehicle_id': state.selectedVehicleId,
          'start_time': startDt.toUtc().toIso8601String(),
          'end_time': endDt.toUtc().toIso8601String(),
        },
      );

      final booking = BookingModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      emit(state.copyWith(isCreating: false, createdBooking: booking));
    } on ApiException catch (e) {
      emit(state.copyWith(isCreating: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isCreating: false, error: e.toString()));
    }
  }

  DateTime? _parsePresetDateTime(String? date, String? time) {
    if (date == null || time == null) {
      return null;
    }

    final normalizedTime = time.length == 5 ? '$time:00' : time;
    return DateTime.tryParse('${date}T$normalizedTime');
  }
}
