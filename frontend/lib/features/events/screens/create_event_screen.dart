import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/event_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_banner.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _latCtrl      = TextEditingController();
  final _lngCtrl      = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    _locationCtrl.dispose(); _latCtrl.dispose(); _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() => _selectedDate = DateTime(
            date.year, date.month, date.day, time.hour, time.minute));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select event date and time')));
      return;
    }

    final success = await context.read<EventProvider>().createEvent({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'locationName': _locationCtrl.text.trim(),
      'latitude': double.parse(_latCtrl.text),
      'longitude': double.parse(_lngCtrl.text),
      'eventDatetime': _selectedDate!.toUtc().toIso8601String(),
    });

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created!'), backgroundColor: AppTheme.primary));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (provider.error != null) ...[
                    ErrorBanner(message: provider.error!, onDismiss: provider.clearError),
                    const SizedBox(height: 16),
                  ],

                  AppTextField(
                    label: 'Event Title',
                    controller: _titleCtrl,
                    maxLength: 100,
                    validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Description',
                    controller: _descCtrl,
                    maxLines: 3,
                    maxLength: 1000,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Location Name',
                    controller: _locationCtrl,
                    validator: (v) => v == null || v.isEmpty ? 'Location is required' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Latitude',
                          controller: _latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Longitude',
                          controller: _lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date/time picker
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppTheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} '
                                  '${_selectedDate!.hour.toString().padLeft(2,'0')}:${_selectedDate!.minute.toString().padLeft(2,'0')}'
                                : 'Select Event Date & Time',
                            style: TextStyle(
                              color: _selectedDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  AppButton(
                    label: 'Create Event',
                    isLoading: provider.isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
