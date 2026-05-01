import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../core/providers/report_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';

class ReportWasteScreen extends StatefulWidget {
  final String? preloadedImagePath;
  final Uint8List? preloadedImageBytes;

  const ReportWasteScreen({
    super.key,
    this.preloadedImagePath,
    this.preloadedImageBytes,
  });

  @override
  State<ReportWasteScreen> createState() => _ReportWasteScreenState();
}

class _ReportWasteScreenState extends State<ReportWasteScreen> {
  final _descCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  XFile? _imageFile;
  double? _latitude;
  double? _longitude;
  bool _gettingLocation = false;
  String? _locationError;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedImageBytes != null) {
      _imageBytes = widget.preloadedImageBytes;
      _imageName = 'captured_image.jpg';
    }
    // On web, we can't auto-get GPS — show manual input
    if (!kIsWeb) {
      _getLocation();
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    // GPS location — only works on mobile
    // On web, user enters coordinates manually
    setState(() { _gettingLocation = false; });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
      _imageFile = picked;
    });
  }

  Future<void> _submit() async {
    if (_imageBytes == null) {
      setState(() => _error = 'Please select an image');
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _error = 'Please enter GPS coordinates');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final api = ApiClient();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          _imageBytes!,
          filename: _imageName ?? 'image.jpg',
        ),
        'latitude': _latitude,
        'longitude': _longitude,
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      });

      await api.dio.post(ApiConstants.reports, data: formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted! +10 pts when approved'),
            backgroundColor: AppTheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? 'Failed to submit report');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Waste')),
      body: LoadingOverlay(
        isLoading: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[
                    ErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
                    const SizedBox(height: 16),
                  ],

                  // Image picker
                  const Text('Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 48,
                                     color: AppTheme.textSecondary),
                                SizedBox(height: 8),
                                Text('Tap to add photo',
                                     style: TextStyle(color: AppTheme.textSecondary)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GPS coordinates (manual on web)
                  const Text('GPS Coordinates', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (kIsWeb)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enter coordinates manually on web. '
                              'Mobile app captures GPS automatically.',
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            hintText: 'e.g. 12.9716',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          onChanged: (v) => _latitude = double.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            hintText: 'e.g. 77.5946',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          onChanged: (v) => _longitude = double.tryParse(v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  AppTextField(
                    label: 'Description (optional)',
                    controller: _descCtrl,
                    maxLines: 3,
                    maxLength: 500,
                    hint: 'Describe the waste you found...',
                  ),
                  const SizedBox(height: 24),

                  AppButton(
                    label: 'Submit Report',
                    isLoading: _loading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
