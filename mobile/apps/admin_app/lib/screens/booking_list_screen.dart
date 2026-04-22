import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

import '../cubits/bookings_cubit.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<BookingsCubit>().loadBookings(
        societyId: authState.user.society,
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'active':
        return AppColors.primary;
      case 'completed':
        return AppColors.textSecondary;
      case 'cancelled':
        return AppColors.error;
      case 'pending_payment':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBookings),
        ],
      ),
      body: BlocBuilder<BookingsCubit, BookingsState>(
        builder: (context, state) {
          if (state.isLoading && state.bookings.isEmpty) {
            return const LoadingWidget(message: 'Loading bookings...');
          }

          if (state.error != null && state.bookings.isEmpty) {
            return AppErrorWidget(
              message: state.error!,
              onRetry: _loadBookings,
            );
          }

          if (state.bookings.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.book_online,
              title: 'No bookings yet',
              subtitle: 'Bookings for your society will appear here',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadBookings(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.bookings.length,
              itemBuilder: (context, index) {
                final booking = state.bookings[index];
                final statusColor = _statusColor(booking.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${booking.bookingNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                booking.status
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (booking.vehicle != null)
                          _BookingInfoRow(
                            icon: Icons.directions_car,
                            text:
                                '${booking.vehicle!.registrationNo} (${booking.vehicle!.vehicleType})',
                          ),
                        if (booking.ownerName != null)
                          _BookingInfoRow(
                            icon: Icons.person_outline,
                            text: 'Owner: ${booking.ownerName}',
                          ),
                        if (booking.ownerPhone != null)
                          _BookingInfoRow(
                            icon: Icons.phone_outlined,
                            text: 'Phone: ${booking.ownerPhone}',
                          ),
                        if (booking.slotNumber != null)
                          _BookingInfoRow(
                            icon: Icons.local_parking,
                            text: 'Slot: ${booking.slotNumber}',
                          ),
                        _BookingInfoRow(
                          icon: Icons.schedule,
                          text:
                              '${_formatDateTime(booking.startTime)} - ${_formatDateTime(booking.endTime)}',
                        ),
                        _BookingInfoRow(
                          icon: Icons.currency_rupee,
                          text:
                              '\u20B9${booking.amount} (${(booking.paymentStatus ?? "unknown").replaceAll('_', ' ')})',
                        ),
                        if (booking.actualEntry != null)
                          _BookingInfoRow(
                            icon: Icons.login,
                            text:
                                'Entry: ${_formatDateTime(booking.actualEntry!)}',
                          ),
                        if (booking.actualExit != null)
                          _BookingInfoRow(
                            icon: Icons.logout,
                            text:
                                'Exit: ${_formatDateTime(booking.actualExit!)}',
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BookingInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BookingInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
