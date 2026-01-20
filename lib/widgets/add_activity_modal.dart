import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/sleep_data.dart';
import '../models/feeding_data.dart';
import '../services/data_service.dart';

enum ActivityType { sleep, feeding }

class AddActivityModal extends StatefulWidget {
  final ActivityType type;
  final String? currentSleepEntryId;
  final SleepData? sleepToEdit;
  final FeedingData? feedingToEdit;

  const AddActivityModal({
    super.key,
    required this.type,
    this.currentSleepEntryId,
    this.sleepToEdit,
    this.feedingToEdit,
  });

  @override
  State<AddActivityModal> createState() => _AddActivityModalState();
}

class _AddActivityModalState extends State<AddActivityModal> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Sleep fields
  late DateTime _sleepStartTime;
  late DateTime _sleepEndTime;
  late TextEditingController _sleepNotesController;

  // Feeding fields
  late DateTime _feedingTime;
  late TextEditingController _amountController;
  late TextEditingController _durationController;
  late String _selectedFeedingType;
  String? _selectedSide;

  bool _isSaving = false;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    _sleepNotesController = TextEditingController(text: widget.sleepToEdit?.notes ?? '');
    _amountController = TextEditingController(text: widget.feedingToEdit?.amountMl.toString() ?? '');
    _durationController = TextEditingController(text: widget.feedingToEdit?.durationMinutes.toString() ?? '10');

    _sleepStartTime = widget.sleepToEdit?.startTime.toDate() ?? DateTime.now();
    _sleepEndTime = widget.sleepToEdit?.endTime?.toDate() ?? DateTime.now();

    _feedingTime = widget.feedingToEdit?.timestamp.toDate() ?? DateTime.now();
    _selectedFeedingType = widget.feedingToEdit?.type ?? 'Bottle';
    _selectedSide = widget.feedingToEdit?.side;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sleepNotesController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, DateTime initialDate, Function(DateTime) onDateTimeSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(minutes: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.type == ActivityType.feeding ? Colors.purple[400]! : Colors.indigo[400]!,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: widget.type == ActivityType.feeding ? Colors.purple[400]! : Colors.indigo[400]!,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          onDateTimeSelected(newDateTime);
        });
      }
    }
  }

  Future<void> _saveSleep() async {
    setState(() => _isSaving = true);
    final dataService = Provider.of<DataService>(context, listen: false);

    try {
      if (widget.currentSleepEntryId != null) {
        await dataService.endSleepEntry(
          widget.currentSleepEntryId!,
          Timestamp.fromDate(_sleepEndTime),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSuccessSnackBar('Sleep session ended!'),
          );
        }
      } else if (widget.sleepToEdit != null) {
        if (_sleepEndTime.isBefore(_sleepStartTime)) {
          throw Exception("End time cannot be before start time.");
        }
        final updatedSleep = SleepData(
          id: widget.sleepToEdit!.id,
          startTime: Timestamp.fromDate(_sleepStartTime),
          endTime: Timestamp.fromDate(_sleepEndTime),
          notes: _sleepNotesController.text,
        );
        await dataService.updateSleepEntry(updatedSleep);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSuccessSnackBar('Sleep session updated!'),
          );
        }
      } else {
        if (_sleepEndTime.isBefore(_sleepStartTime)) {
          throw Exception("End time cannot be before start time.");
        }
        final newSleep = SleepData(
          id: _uuid.v4(),
          startTime: Timestamp.fromDate(_sleepStartTime),
          endTime: Timestamp.fromDate(_sleepEndTime),
          notes: _sleepNotesController.text,
        );
        await dataService.addSleepEntry(newSleep);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSuccessSnackBar('Sleep session logged!'),
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar(e.toString().replaceAll('Exception: ', '')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveFeeding() async {
    setState(() => _isSaving = true);
    final dataService = Provider.of<DataService>(context, listen: false);

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final int duration = int.tryParse(_durationController.text) ?? 0;

    if (duration <= 0 && amount <= 0 && _selectedFeedingType != 'Breast') {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Please enter duration or amount.'),
        );
      }
      return;
    }

    try {
      final feedingData = FeedingData(
        id: widget.feedingToEdit?.id ?? _uuid.v4(),
        timestamp: Timestamp.fromDate(_feedingTime),
        amountMl: amount,
        type: _selectedFeedingType,
        side: _selectedFeedingType == 'Breast' ? _selectedSide : null,
        durationMinutes: duration,
      );

      if (widget.feedingToEdit != null) {
        await dataService.updateFeedingEntry(feedingData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSuccessSnackBar('Feeding updated!'),
          );
        }
      } else {
        await dataService.addFeedingEntry(feedingData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSuccessSnackBar('Feeding logged!'),
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Error: ${e.toString()}'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final day = dt.day;
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$month $day, $time';
  }

  SnackBar _buildSuccessSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Text(message),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  SnackBar _buildErrorSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.sleepToEdit != null || widget.feedingToEdit != null;
    bool isEndingSleep = widget.currentSleepEntryId != null;
    final color = widget.type == ActivityType.feeding ? Colors.purple[400]! : Colors.indigo[400]!;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(color, isEndingSleep, isEditing),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: widget.type == ActivityType.sleep
                        ? _buildSleepForm(color, isEndingSleep)
                        : _buildFeedingForm(color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color color, bool isEndingSleep, bool isEditing) {
    final icon = widget.type == ActivityType.feeding ? Icons.local_dining : Icons.king_bed;
    final title = widget.type == ActivityType.sleep
        ? (isEndingSleep ? 'End Sleep Session' : (isEditing ? 'Edit Sleep' : 'Log Sleep Session'))
        : (isEditing ? 'Edit Feeding' : 'Log Feeding');

    // Get lighter shade for gradient
    final lightColor = Color.lerp(color, Colors.white, 0.3)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, lightColor],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepForm(Color color, bool isEndingSleep) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isEndingSleep) ...[
          _buildSectionTitle('Start Time'),
          const SizedBox(height: 12),
          _buildTimeSelector(
            context,
            _formatDateTime(_sleepStartTime),
            Icons.wb_sunny,
            color,
                () => _selectDateTime(context, _sleepStartTime, (dt) => _sleepStartTime = dt),
          ),
          const SizedBox(height: 24),
        ],
        _buildSectionTitle('End Time'),
        const SizedBox(height: 12),
        _buildTimeSelector(
          context,
          _formatDateTime(_sleepEndTime),
          Icons.nightlight_round,
          color,
              () => _selectDateTime(context, _sleepEndTime, (dt) => _sleepEndTime = dt),
        ),
        if (!isEndingSleep) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Notes (Optional)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: TextField(
              controller: _sleepNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Add any observations...',
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        _buildSubmitButton(
          isEndingSleep
              ? 'End Sleep Session'
              : (widget.sleepToEdit != null ? 'Update Sleep' : 'Save Sleep'),
          color,
          Icons.check_circle,
          _saveSleep,
        ),
      ],
    );
  }

  Widget _buildFeedingForm(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Feeding Time'),
        const SizedBox(height: 12),
        _buildTimeSelector(
          context,
          _formatDateTime(_feedingTime),
          Icons.access_time,
          color,
              () => _selectDateTime(context, _feedingTime, (dt) => _feedingTime = dt),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Feeding Type'),
        const SizedBox(height: 12),
        _buildFeedingTypeSelector(),
        if (_selectedFeedingType == 'Breast') ...[
          const SizedBox(height: 24),
          _buildSectionTitle('Side'),
          const SizedBox(height: 12),
          _buildSideSelector(),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Amount'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _amountController,
                    'ml',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Duration'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _durationController,
                    'minutes',
                    Icons.timer,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSubmitButton(
          widget.feedingToEdit != null ? 'Update Feeding' : 'Save Feeding',
          color,
          Icons.check_circle,
          _saveFeeding,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context, String time, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.edit, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedingTypeSelector() {
    final types = [
      {'name': 'Bottle', 'icon': Icons.baby_changing_station},
      {'name': 'Breast', 'icon': Icons.child_care},
      {'name': 'Solid', 'icon': Icons.restaurant},
    ];

    return Row(
      children: types.map((type) {
        final isSelected = _selectedFeedingType == type['name'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedFeedingType = type['name'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [Colors.purple[400]!, Colors.purple[300]!])
                    : null,
                color: isSelected ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.purple[400]! : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSideSelector() {
    return Row(
      children: ['Left', 'Right'].map((side) {
        final isSelected = _selectedSide == side;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedSide = side),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [Colors.purple[400]!, Colors.purple[300]!])
                    : null,
                color: isSelected ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.purple[400]! : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                side,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String suffix, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                suffixText: suffix,
                suffixStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(String text, Color color, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}