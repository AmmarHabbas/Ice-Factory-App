import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ice_cube_app/features/schedule/add_new_trip.dart';
import 'package:ice_cube_app/features/schedule/trip_detail_screen.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/currency_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/widgets/shared_widgets.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  String _filter = 'All';

  Future<void> _pickCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exchangeRate = ref.watch(exchangeRateProvider);
    final tripsAsync = ref
        .watch(tripRepositoryProvider)
        .watchTripsForDate(_selectedDate);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNewTrip()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'New Trip',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentLocation: '/schedule'),
      appBar: AppHeader(
        title: "Today's Schedule",
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
            tooltip: 'Pick Date',
            onPressed: _pickCalendarDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector strip
          _DateStrip(
            selectedDate: _selectedDate,
            onDateChanged: (d) => setState(() => _selectedDate = d),
            onPickCalendar: _pickCalendarDate,
          ),

          const SizedBox(height: AppDimensions.sm),

          // Filter chips
          FilterChipRow(
            chips: const ['All', 'Pending', 'In Progress', 'Completed'],
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: AppDimensions.md),

          // Stream Body
          Expanded(
            child: StreamBuilder<List<Trip>>(
              stream: tripsAsync,
              builder: (context, snapshot) {
                final tripsList = snapshot.data ?? [];
                final filtered = tripsList.where((t) {
                  return _filter == 'All' ||
                      t.status.toLowerCase() == _filter.toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.event_note_outlined,
                    title: 'No Trips Scheduled',
                    subtitle:
                        'No delivery trips found for ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}. Tap "+ New Trip" to schedule one.',
                  );
                }

                return Column(
                  children: [
                    _DaySummaryBanner(
                      trips: filtered,
                      exchangeRate: exchangeRate,
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.containerMargin,
                          0,
                          AppDimensions.containerMargin,
                          80,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _TripTimelineCard(
                          trip: filtered[i],
                          isLast: i == filtered.length - 1,
                          exchangeRate: exchangeRate,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onPickCalendar;
  const _DateStrip({
    required this.selectedDate,
    required this.onDateChanged,
    required this.onPickCalendar,
  });

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemWidth = 54;
  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _generateDays();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _generateDays() {
    final centerDate = widget.selectedDate;
    _days = List.generate(
      21,
      (i) => DateTime(centerDate.year, centerDate.month, centerDate.day)
          .add(Duration(days: i - 10)),
    );
  }

  @override
  void didUpdateWidget(covariant _DateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final index =
          _days.indexWhere((d) => _isSameDay(d, widget.selectedDate));
      if (index == -1) {
        setState(() {
          _generateDays();
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return DateFormat('yyyyMMdd').format(a) == DateFormat('yyyyMMdd').format(b);
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    final index = _days.indexWhere((d) => _isSameDay(d, widget.selectedDate));
    if (index == -1) return;

    final itemExtent = _itemWidth + AppDimensions.sm;
    final viewportWidth = _scrollController.position.viewportDimension;

    final targetOffset =
        (index * itemExtent) - (viewportWidth / 2) + (itemExtent / 2);

    final clampedOffset = targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: AppColors.surfaceContainerLowest,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.containerMargin,
                vertical: AppDimensions.sm,
              ),
              itemCount: _days.length,
              itemBuilder: (ctx, i) {
                final day = _days[i];
                final isSelected = _isSameDay(day, widget.selectedDate);
                final isToday = _isSameDay(day, DateTime.now());

                return GestureDetector(
                  onTap: () => widget.onDateChanged(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: AppDimensions.sm),
                    width: _itemWidth,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEE').format(day).toUpperCase(),
                              maxLines: 1,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                color: isSelected
                                    ? Colors.white70
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${day.day}',
                              maxLines: 1,
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppColors.primary, size: 22),
            tooltip: 'Pick date',
            onPressed: widget.onPickCalendar,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _DaySummaryBanner extends StatelessWidget {
  final List<Trip> trips;
  final double exchangeRate;
  const _DaySummaryBanner({required this.trips, required this.exchangeRate});

  @override
  Widget build(BuildContext context) {
    final completed = trips.where((t) => t.status == 'Completed').length;
    final totalStops = trips.fold(0, (s, t) => s + t.totalStops);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.containerMargin,
      ),
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Trips',
              value: '$completed / ${trips.length}',
              icon: Icons.local_shipping_outlined,
              color: AppColors.primary,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.outlineVariant),
          Expanded(
            child: _SummaryItem(
              label: 'Stops',
              value: '$totalStops',
              icon: Icons.inventory_2_outlined,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TripTimelineCard extends StatelessWidget {
  final Trip trip;
  final bool isLast;
  final double exchangeRate;
  const _TripTimelineCard({
    required this.trip,
    required this.isLast,
    required this.exchangeRate,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (trip.status) {
      'Completed' => AppColors.paid,
      'In Progress' => AppColors.primary,
      _ => AppColors.outline,
    };

    final timeStr = DateFormat('HH:mm').format(trip.date);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column — fixed width, text clipped to fit
        SizedBox(
          width: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                timeStr,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 2,
                height: 80,
                color: isLast ? Colors.transparent : AppColors.outlineVariant,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // Card — tappable, opens TripDetailScreen
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripDetailScreen(trip: trip),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border(left: BorderSide(color: statusColor, width: 3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row: truck number + status chip — Flexible prevents overflow
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            trip.truckNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusChip(label: trip.status, color: statusColor),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.outline),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Driver name row — Expanded prevents overflow
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Driver: ${trip.driverName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stops: ${trip.completedStops} / ${trip.totalStops} completed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: AppColors.secondary,
                          ),
                        ),
                        if (trip.iceLoadKg > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.ac_unit,
                                    size: 12, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${trip.iceLoadKg.toStringAsFixed(0)} kg',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
