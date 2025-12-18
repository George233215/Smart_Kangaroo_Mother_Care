import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _reminderType = 'Feeding';
  TimeOfDay? _selectedTime;
  List<fln.PendingNotificationRequest> _pendingReminders = [];
  int _nextNotificationId = 0; // Simple way to generate unique IDs

  @override
  void initState() {
    super.initState();
    _loadPendingReminders();
  }

  Future<void> _loadPendingReminders() async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    final reminders = await notificationService.getPendingNotifications();

    // Find the next available ID by checking existing ones
    if (reminders.isNotEmpty) {
      _nextNotificationId = reminders.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
    } else {
      _nextNotificationId = 1;
    }

    if (mounted) {
      setState(() {
        _pendingReminders = reminders;
      });
    }
  }

  // --- UI Handlers ---

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _scheduleReminder() async {
    if (_formKey.currentState!.validate() && _selectedTime != null) {
      final notificationService = Provider.of<NotificationService>(context, listen: false);

      // Schedule the reminder as a daily repeating alarm
      await notificationService.scheduleDailyNotification(
        id: _nextNotificationId,
        title: 'KMC Reminder: $_reminderType',
        body: 'Time to $_reminderType the baby!',
        scheduledTime: _selectedTime!, // pass Flutter's TimeOfDay
        payload: _reminderType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scheduled $_reminderType reminder for ${_selectedTime!.format(context)} daily!')),
      );

      // Update the list and ID
      _loadPendingReminders();
    } else if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time.')),
      );
    }
  }

  void _cancelReminder(int id) async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    await notificationService.cancelNotification(id);
    _loadPendingReminders();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder cancelled.')),
    );
  }

  // --- Widget Builders ---

  String _formatReminderTitle(fln.PendingNotificationRequest request) {
    if (request.title == null || request.body == null) return 'Unknown Reminder';
    final type = request.title!.split(':').last.trim();
    return '$type at ${request.payload}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Reminders',
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
        ),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink[400]!, Colors.pink[300]!],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.pink[300]!, Colors.pink[200]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.alarm_add, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'New Daily Alarm',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.pink[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _reminderType,
                            decoration: InputDecoration(
                              labelText: 'Reminder For',
                              labelStyle: TextStyle(color: Colors.pink[700]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              prefixIcon: Icon(Icons.category, color: Colors.pink[400]),
                            ),
                            items: ['Feeding', 'Medication']
                                .map((label) => DropdownMenuItem(
                              value: label,
                              child: Text(label),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _reminderType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        InkWell(
                          onTap: () => _selectTime(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.pink[200]!, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.pink[400], size: 26),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Alarm Time',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedTime == null
                                            ? 'Tap to select time'
                                            : '${_selectedTime!.format(context)} (Daily Repeat)',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.pink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.pink[300]),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _scheduleReminder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.alarm_on, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Schedule Reminder',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Active Alarms',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 16),

              _pendingReminders.isEmpty
                  ? Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.alarm_off, size: 60, color: Colors.pink[200]),
                      const SizedBox(height: 12),
                      const Text(
                        'No active reminders set',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingReminders.length,
                itemBuilder: (context, index) {
                  final reminder = _pendingReminders[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink[300]!, Colors.pink[200]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.alarm, color: Colors.white, size: 26),
                      ),
                      title: Text(
                        reminder.title ?? 'Reminder',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.pink[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Daily Repeat',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.pink,
                            ),
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete, color: Colors.red, size: 22),
                        ),
                        onPressed: () => _cancelReminder(reminder.id),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
