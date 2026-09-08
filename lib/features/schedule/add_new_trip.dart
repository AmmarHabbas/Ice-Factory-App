import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/repository_providers.dart';

class AddNewTrip extends ConsumerStatefulWidget {
  const AddNewTrip({super.key});

  @override
  ConsumerState<AddNewTrip> createState() => _AddNewTripState();
}

enum TripStatus { completed, inProgress, pending }

class _AddNewTripState extends ConsumerState<AddNewTrip> {
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _iceLoadController = TextEditingController();
  final TextEditingController _driverController = TextEditingController();

  TimeOfDay? _selectedTime = TimeOfDay.now();
  DateTime? _selectedDate = DateTime.now();
  TripStatus _selectedStatus = TripStatus.pending;
  bool _isSaving = false;

  static const Color navy = AppColors.primary;
  static const Color cardBlue = AppColors.surfaceContainer;
  static const Color labelGrey = AppColors.onSurfaceVariant;

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
        return 'Completed';
      case TripStatus.inProgress:
        return 'In Progress';
      case TripStatus.pending:
        return 'Pending';
    }
  }

  Future<void> _createTrip() async {
    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination / location')),
      );
      return;
    }

    final iceLoad = double.tryParse(_iceLoadController.text.trim()) ?? 0.0;
    if (iceLoad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid ice load in kg')),
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

      final tripId = 'TRIP-${DateTime.now().millisecondsSinceEpoch}';
      final statusStr = _statusString;
      final isCompleted = statusStr == 'Completed';
      final isPending = statusStr == 'Pending';

      final trip = Trip(
        id: tripId,
        truckNumber: destination,
        driverName: _driverController.text.trim().isEmpty
            ? ''
            : _driverController.text.trim(),
        date: tripDateTime,
        status: statusStr,
        totalStops: 1,
        completedStops: isCompleted ? 1 : 0,
        pendingStops: isPending ? 1 : 0,
        iceLoadKg: iceLoad,
      );

      final stop = TripStop(
        id: 'STOP-${DateTime.now().millisecondsSinceEpoch}',
        tripId: tripId,
        stopNumber: 1,
        customerId: 'cust-gen',
        customerName: destination,
        address: destination,
        eta: _timeLabel,
        status: statusStr,
        estimatedQuantity: '${iceLoad.toStringAsFixed(0)} kg',
        requiredTemperature: '-18°C',
      );

      await ref.read(tripRepositoryProvider).createTrip(trip, stop: stop);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip to "$destination" created ($statusStr)'),
            backgroundColor: AppColors.paid,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating trip: $e'),
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
              _buildCreateButton(),
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
          child: const Icon(Icons.local_shipping, size: 20, color: navy),
        ),
        const SizedBox(width: 12),
        Text(
          'New Trip',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: navy,
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
          _sectionLabel('DESTINATION / LOCATION'),
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
                      hintText: 'e.g. Al Safa Supermarket / King Fahd Rd',
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
          _sectionLabel('DRIVER / TRUCK FLEET'),
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
                      hintText: 'Driver name or Truck #',
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
                _sectionLabel('TIME'),
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
                _sectionLabel('DATE'),
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
          _sectionLabel('ICE LOAD (KG)'),
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
                  'kg',
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
          _sectionLabel('INITIAL STATUS'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statusChip(
                  label: 'Completed',
                  icon: Icons.check_circle_outline,
                  status: TripStatus.completed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusChip(
                  label: 'In Progress',
                  icon: Icons.local_shipping_outlined,
                  status: TripStatus.inProgress,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusChip(
                  label: 'Pending',
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

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _createTrip,
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
                    'Create Trip',
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                ],
              ),
      ),
    );
  }
}
