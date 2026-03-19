import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// States
abstract class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object?> get props => [];
}

class ScanInitial extends ScanState {
  const ScanInitial();
}

class ScanLoading extends ScanState {
  const ScanLoading();
}

class ScanSuccess extends ScanState {
  final Map<String, dynamic> data;

  const ScanSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

class ScanError extends ScanState {
  final String message;

  const ScanError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ScanCubit extends Cubit<ScanState> {
  final ApiClient _apiClient;

  ScanCubit({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const ScanInitial());

  Future<void> validateEntry(String qrToken) async {
    emit(const ScanLoading());
    try {
      final response = await _apiClient.post(
        ApiEndpoints.qrEntry,
        data: {'qr_token': qrToken},
      );
      final data = response.data as Map<String, dynamic>;
      emit(ScanSuccess(data));
    } on ApiException catch (e) {
      emit(ScanError(e.message));
    } catch (e) {
      emit(ScanError(e.toString()));
    }
  }

  Future<void> validateExit(String qrToken) async {
    emit(const ScanLoading());
    try {
      final response = await _apiClient.post(
        ApiEndpoints.qrExit,
        data: {'qr_token': qrToken},
      );
      final data = response.data as Map<String, dynamic>;
      emit(ScanSuccess(data));
    } on ApiException catch (e) {
      emit(ScanError(e.message));
    } catch (e) {
      emit(ScanError(e.toString()));
    }
  }

  void reset() {
    emit(const ScanInitial());
  }
}
