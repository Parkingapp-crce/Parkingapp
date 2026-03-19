import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:core/core.dart';

import '../cubits/bookings_cubit.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BookingsCubit(GetIt.instance<ApiClient>())..loadBookings(),
      child: const _BookingListContent(),
    );
  }
}

class _BookingListContent extends StatelessWidget {
  const _BookingListContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: Column(
        children: [
          _FilterTabs(),
          Expanded(
            child: BlocBuilder<BookingsCubit, BookingsState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const LoadingWidget(message: 'Loading bookings...');
                }

                if (state.error != null) {
                  return AppErrorWidget(
                    message: state.error!,
                    onRetry: () =>
                        context.read<BookingsCubit>().loadBookings(),
                  );
                }

                final bookings = state.filteredBookings;

                if (bookings.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.book_outlined,
                    title: 'No bookings found',
                    subtitle: 'Your bookings will appear here',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<BookingsCubit>().loadBookings(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      return _BookingCard(booking: bookings[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final List<Map<String, String>> _filters = const [
    {'label': 'All', 'value': 'all'},
    {'label': 'Active', 'value': 'active'},
    {'label': 'Confirmed', 'value': 'confirmed'},
    {'label': 'Pending', 'value': 'pending_payment'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingsCubit, BookingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: _filters.map((filter) {
              final isSelected = state.statusFilter == filter['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => context
                      .read<BookingsCubit>()
                      .setFilter(filter['value']!),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      filter['label']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'active':
        return AppColors.primary;
      case 'pending_payment':
        return AppColors.warning;
      case 'completed':
        return AppColors.textSecondary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'PENDING PAYMENT';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    DateTime? startDt;
    DateTime? endDt;
    try {
      startDt = DateTime.parse(booking.startTime).toLocal();
      endDt = DateTime.parse(booking.endTime).toLocal();
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/bookings/${booking.id}'),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _statusColor(booking.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(booking.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(booking.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (booking.societyName != null)
                _DetailRow(
                  icon: Icons.apartment,
                  text: booking.societyName!,
                ),
              if (booking.slotNumber != null)
                _DetailRow(
                  icon: Icons.grid_view,
                  text: 'Slot ${booking.slotNumber}',
                ),
              if (startDt != null)
                _DetailRow(
                  icon: Icons.calendar_today,
                  text: dateFormat.format(startDt),
                ),
              if (startDt != null && endDt != null)
                _DetailRow(
                  icon: Icons.access_time,
                  text:
                      '${timeFormat.format(startDt)} - ${timeFormat.format(endDt)}',
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\u20B9${booking.amount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
