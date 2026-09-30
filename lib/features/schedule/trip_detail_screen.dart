import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/repository_providers.dart';
import 'add_new_trip.dart'; // reuse TripStatus enum

class TripDetailScreen extends ConsumerStatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  late final TextEditingController _destinationController;
  late final TextEditingController _iceLoadController;
  late final TextEditingController _driverController;

  TimeOfDay? _selectedTime;
  DateTime? _selectedDate;
  TripStatus _selectedStatus = TripStatus.pending;
  bool _isSaving = false;

  static const Color navy = AppColors.primary;
  static const Color cardBlue = AppColors.surfaceContainer;
  static const Color labelGrey = AppColors.onSurfaceVariant;

  @override
  void initState() {
    super.initState();
    final t = widget.trip;
    _destinationController = TextEditingController(text: t.truckNumber);
    _iceLoadController = TextEditingController(
      text: t.iceLoadKg.toStringAsFixed(0),
    );
    _driverController = TextEditingController(text: t.driverName);
    _selectedDate = t.date;
    _selectedTime = TimeOfDay(hour: t.date.hour, minute: t.date.minute);

    // Parse existing status
    if (t.status == 'Completed') {
      _selectedStatus = TripStatus.completed;
    } else if (t.status == 'In Progress') {
      _selectedStatus = TripStatus.inProgress;
    } else {
      _selectedStatus = TripStatus.pending;
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _iceLoadController.dispose();
    _driverController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  String get _timeLabel {
    if (_selectedTime == null) return '--:-- --';
    return _selectedTime!.format(context);
  }

  String get _dateLabel {
    if (_selectedDate == null) return 'mm/dd/yy';
    final d = _selectedDate!;
    return '${d.month.toString().padLeft(2, '0')}/'
        '${d.day.toString().padLeft(2, '0')}/'
        '${(d.year % 100).toString().padLeft(2, '0')}';
  }

  String get _statusString {
    switch (_selectedStatus) {
      case TripStatus.completed:
        return context.translate('completed');
      case TripStatus.inProgress:
        return context.translate('in_progress');
      case TripStatus.pending:
        return context.translate('pending');
    }
  }

  Future<void> _saveTrip() async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.translate('destination_required'))),
      );
      return;
    }

    final iceLoad = double.tryParse(_iceLoadController.text.trim()) ?? 0.0;
    if (iceLoad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.translate('valid_ice_load'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final date = _selectedDate ?? DateTime.now();
      final time = _selectedTime ?? TimeOfDay.now();
      final tripDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final statusStr = _statusString;
      final isCompleted = statusStr == context.translate('completed');
      final isPending = statusStr == context.translate('pending');

      final updatedTrip = widget.trip.copyWith(
        truckNumber: destination,
        driverName: _driverController.text.trim().isEmpty
            ? widget.trip.driverName
            : _driverController.text.trim(),
        date: tripDateTime,
        status: statusStr,
        completedStops: isCompleted ? widget.trip.totalStops : 0,
        pendingStops: isPending ? widget.trip.totalStops : 0,
        iceLoadKg: iceLoad,
      );

      await ref.read(tripRepositoryProvider).updateTrip(updatedTrip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.translate('trip_updated')} "$destination" ${context.translate('to')} $statusStr',
            ),
            backgroundColor: AppColors.paid,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.translate('error_updating_trip')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildDestinationCard(),
              const SizedBox(height: 16),
              _buildDriverCard(),
              const SizedBox(height: 16),
              _buildTimeDateRow(),
              const SizedBox(height: 16),
              _buildIceLoadCard(),
              const SizedBox(height: 16),
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildSaveButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cardBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: navy),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cardBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.edit_road, size: 20, color: navy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('trip_details'),
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: navy,
                ),
              ),
              Text(
                context.translate('trip_id').replaceAll('{id}', widget.trip.id),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: labelGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: cardBlue,
    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
  );

  BoxDecoration get _innerFieldDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  Widget _sectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: navy,
        ),
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel(context.translate('destination_location')),
          const SizedBox(height: 10),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: _innerFieldDecoration,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: navy, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: context.translate('destination_hint'),
                      hintStyle: GoogleFonts.manrope(
                        color: labelGrey,
                        fontSize: 14,
                      ),
                      isCollapsed: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel(context.translate('driver_truck_fleet')),
          const SizedBox(height: 10),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: _innerFieldDecoration,
            child: Row(
              children: [
                const Icon(Icons.badge_outlined, color: navy, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _driverController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: context.translate('driver_name_or_truck'),
                      hintStyle: GoogleFonts.manrope(
                        color: labelGrey,
                        fontSize: 14,
                      ),
                      isCollapsed: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDateRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel(context.translate('time_label')),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: _innerFieldDecoration,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.access_time, color: navy, size: 18),
                        Text(
                          _timeLabel,
                          style: GoogleFonts.jetBrainsMono(
                            color: navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: navy,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel(context.translate('date_label')),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: _innerFieldDecoration,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: navy,
                          size: 16,
                        ),
                        Text(
                          _dateLabel,
                          style: GoogleFonts.jetBrainsMono(
                            color: navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: navy,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIceLoadCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel(context.translate('ice_load_kg')),
          const SizedBox(height: 10),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: _innerFieldDecoration,
            child: Row(
              children: [
                const Icon(Icons.ac_unit, color: navy, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _iceLoadController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: '0',
                    ),
                  ),
                ),
                const Icon(
                  Icons.inventory_2_outlined,
                  color: labelGrey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  context.translate('kg'),
                  style: GoogleFonts.jetBrainsMono(
                    color: labelGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel(context.translate('status_label')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statusChip(
                  label: context.translate('completed'),
                  icon: Icons.check_circle_outline,
                  status: TripStatus.completed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusChip(
                  label: context.translate('in_progress'),
                  icon: Icons.local_shipping_outlined,
                  status: TripStatus.inProgress,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusChip(
                  label: context.translate('pending'),
                  icon: Icons.schedule_outlined,
                  status: TripStatus.pending,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip({
    required String label,
    required IconData icon,
    required TripStatus status,
  }) {
    final bool selected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? navy : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? navy : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (!selected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : navy),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: selected ? Colors.white : navy,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveTrip,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          disabledBackgroundColor: navy.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.translate('save_changes'),
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                ],
              ),
      ),
    );
  }
}
