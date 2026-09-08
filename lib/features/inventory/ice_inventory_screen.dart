import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/repositories/app_repository.dart';
import '../../shared/widgets/main_shell.dart';

class IceInventoryScreen extends ConsumerStatefulWidget {
  const IceInventoryScreen({super.key});

  @override
  ConsumerState<IceInventoryScreen> createState() => _IceInventoryScreenState();
}

class _IceInventoryScreenState extends ConsumerState<IceInventoryScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _addAmountCtrl = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _addAmountCtrl.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _selectDate(picked);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _handleAddIce() async {
    final text = _addAmountCtrl.text.trim();
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid ice quantity in kg'),
        ),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      await ref
          .read(iceInventoryRepositoryProvider)
          .addIceInventory(
            amountKg: amount,
            date: _selectedDate,
            notes: 'Production Batch Addition',
          );
      _addAmountCtrl.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${amount.toStringAsFixed(0)} kg ice to ${DateFormat('MMM d').format(_selectedDate)}',
            ),
            backgroundColor: AppColors.paid,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add ice: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  Future<void> _editInventoryEntry(IceInventoryAdjustment adjustment) async {
    final amountController = TextEditingController(
      text: adjustment.amountKg.toStringAsFixed(0),
    );
    final notesController = TextEditingController(text: adjustment.title);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Inventory Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount (kg)'),
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) {
      amountController.dispose();
      notesController.dispose();
      return;
    }

    final amount = double.tryParse(amountController.text.trim());
    final notes = notesController.text.trim();
    amountController.dispose();
    notesController.dispose();
    if (amount == null || amount <= 0) return;

    await ref
        .read(iceInventoryRepositoryProvider)
        .updateIceInventory(id: adjustment.id, amountKg: amount, notes: notes);
  }

  Future<void> _deleteInventoryEntry(IceInventoryAdjustment adjustment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Inventory Entry?'),
        content: Text(
          '${adjustment.amountKg.toStringAsFixed(0)} kg will be removed from this day.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await ref
          .read(iceInventoryRepositoryProvider)
          .deleteIceInventory(adjustment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(iceInventoryStreamProvider(_selectedDate));
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final isYesterday = _isSameDay(
      _selectedDate,
      DateTime.now().subtract(const Duration(days: 1)),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: const AppNavigationDrawer(currentLocation: '/ice-inventory'),
      appBar: AppHeader(
        title: 'Ice Inventory',
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppColors.primary),
            tooltip: 'Choose Date',
            onPressed: _pickCustomDate,
          ),
        ],
      ),
      body: inventoryAsync.when(
        data: (snapshot) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.containerMargin,
              AppDimensions.md,
              AppDimensions.containerMargin,
              32,
            ),
            children: [
              // ── Date Selector Bar ──────────────────────────────────────────
              _buildDateSelectorBar(isYesterday, isToday),

              const SizedBox(height: AppDimensions.md),

              // ── Main Action Card: Add Inventory ───────────────────────────
              _buildAddInventoryCard(),

              const SizedBox(height: AppDimensions.md),

              // ── 3 Displayed Values Metrics Grid ───────────────────────────
              _buildMetricsGrid(snapshot),

              const SizedBox(height: AppDimensions.lg),

              // ── Visual Progress: Inventory Status ─────────────────────────
              _buildInventoryStatusRing(snapshot),

              const SizedBox(height: AppDimensions.lg),

              // ── Recent Adjustments Feed ───────────────────────────────────
              _buildRecentAdjustments(snapshot.adjustments),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading inventory: $e')),
      ),
    );
  }

  Widget _buildDateSelectorBar(bool isYesterday, bool isToday) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                _selectDate(DateTime.now().subtract(const Duration(days: 1))),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isYesterday ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Text(
                'Yesterday',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isYesterday
                      ? Colors.white
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _selectDate(DateTime.now()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Text(
                'Today',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isToday ? Colors.white : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _pickCustomDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: (!isToday && !isYesterday)
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: (!isToday && !isYesterday)
                        ? Colors.white
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (!isToday && !isYesterday)
                          ? Colors.white
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddInventoryCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Inventory',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Update total available ice for ${DateFormat('MMM d').format(_selectedDate)}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.ac_unit,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addAmountCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter amount (e.g. 100)',
                            hintStyle: GoogleFonts.manrope(
                              color: AppColors.outline,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                          onSubmitted: (_) => _handleAddIce(),
                        ),
                      ),
                      Text(
                        'kg',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isAdding ? null : _handleAddIce,
                  icon: _isAdding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: const Text('Add Ice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(IceInventorySnapshot snapshot) {
    return Column(
      children: [
        // Available (Full Width Featured Card)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Available Ice Stock',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    snapshot.available.toStringAsFixed(0),
                    style: GoogleFonts.manrope(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'kg',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.sm),

        // Total Added & Total Sold 2-Column Row
        Row(
          children: [
            // Total Added
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.download,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Total Added',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          snapshot.totalAdded.toStringAsFixed(0),
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'kg',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            // Total Sold
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.upload,
                          size: 16,
                          color: AppColors.unpaid,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Total Sold',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          snapshot.totalSold.toStringAsFixed(0),
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'kg',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventoryStatusRing(IceInventorySnapshot snapshot) {
    final total = snapshot.totalAdded;
    final sold = snapshot.totalSold;
    final ratio = total > 0 ? (sold / total).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Status',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: _ProgressRingPainter(
                      progress: ratio,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      progressColor: AppColors.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percentage%',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Sold',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAdjustments(List<IceInventoryAdjustment> adjustments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Recent Adjustments',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        if (adjustments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Text(
              'No adjustments logged for this date.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            padding: const EdgeInsets.all(AppDimensions.sm),
            child: Column(
              children: adjustments.map((adj) {
                final isAdd = adj.isAddition;
                final timeStr = DateFormat('hh:mm a').format(adj.timestamp);

                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                    vertical: AppDimensions.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isAdd)
                        PopupMenuButton<String>(
                          tooltip: 'Manage inventory entry',
                          onSelected: (action) {
                            if (action == 'edit') {
                              _editInventoryEntry(adj);
                            } else {
                              _deleteInventoryEntry(adj);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isAdd
                              ? AppColors.primaryContainer
                              : AppColors.unpaidContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAdd ? Icons.add : Icons.remove,
                          size: 18,
                          color: isAdd ? Colors.white : AppColors.unpaid,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              adj.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAdd
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.unpaid.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSmall,
                          ),
                        ),
                        child: Text(
                          '${isAdd ? '+' : '-'} ${adj.amountKg.toStringAsFixed(0)} kg',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isAdd ? AppColors.primary : AppColors.unpaid,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 10.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
