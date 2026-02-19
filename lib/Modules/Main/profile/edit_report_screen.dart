import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/firebase/firebase_config.dart';
import '../../../core/services/pet_reports_service.dart';

class EditReportScreen extends StatefulWidget {
  final String reportId;
  final String collection;
  final String type; // lost | found | adoption | breeding

  const EditReportScreen({
    super.key,
    required this.reportId,
    required this.collection,
    required this.type,
  });

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _addressController;
  bool _isActive = true;
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _doc;
  String? _loadError; // Either translation key (e.g. errors.report_not_found) or raw error string

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _contactNameController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadReport();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final snap = await FirebaseConfig.firestore
          .collection(widget.collection)
          .doc(widget.reportId)
          .get();
      if (!snap.exists) {
        setState(() {
          _loading = false;
          _loadError = 'errors.report_not_found';
        });
        return;
      }
      final data = snap.data() as Map<String, dynamic>;
      _doc = data;

      final pd = data['petDetails'] as Map<String, dynamic>? ?? {};
      final pi = data['petInfo'] as Map<String, dynamic>? ?? {};
      final ci = data['contactInfo'] as Map<String, dynamic>? ?? {};
      final loc = data['location'] ?? data['locationInfo'];
      final locMap = loc is Map ? loc as Map<String, dynamic> : <String, dynamic>{};

      _titleController.text = (data['title'] ?? '').toString();
      _descriptionController.text =
          (data['description'] ?? pd['description'] ?? pi['description'] ?? '').toString();
      _contactNameController.text =
          (ci['name'] ?? data['contactName'] ?? '').toString();
      _contactPhoneController.text =
          (ci['phone'] ?? data['contactPhone'] ?? '').toString();
      _addressController.text =
          (locMap['address'] ?? data['address'] ?? data['lastSeenLocation'] ?? data['foundLocation'] ?? '').toString();
      _isActive = data['isActive'] != false;

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updates = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isActive': _isActive,
      };

      final ci = _doc?['contactInfo'] as Map<String, dynamic>? ?? {};
      updates['contactInfo'] = {
        ...ci,
        'name': _contactNameController.text.trim(),
        'phone': _contactPhoneController.text.trim(),
      };

      final locKey = widget.type == 'breeding' ? 'locationInfo' : 'location';
      final loc = _doc?['location'] ?? _doc?['locationInfo'];
      final locMap = loc is Map ? Map<String, dynamic>.from(loc as Map) : <String, dynamic>{};
      locMap['address'] = _addressController.text.trim();
      updates[locKey] = locMap;

      if (widget.type == 'lost' || widget.type == 'found') {
        final pd = _doc?['petDetails'] as Map<String, dynamic>? ?? {};
        updates['petDetails'] = {
          ...pd,
          'description': _descriptionController.text.trim(),
        };
      }

      await PetReportsService.updateReport(
        reportId: widget.reportId,
        collection: widget.collection,
        updates: updates,
      );

      if (!mounted) return;
      final t = Provider.of<AppLanguage>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.translate('profile.edit_report_saved')),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${Provider.of<AppLanguage>(context, listen: false).translate('profile.edit_report_error')}: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<AppLanguage>(context);
    final title = t.translate('profile.edit_report');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48.sp, color: AppTheme.error),
                        SizedBox(height: 16.h),
                        Text(
                          _loadError!.startsWith('errors.')
                              ? t.translate(_loadError!)
                              : _loadError!,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        TextButton.icon(
                          onPressed: _loadReport,
                          icon: const Icon(Icons.refresh),
                          label: Text(t.translate('common.retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: t.translate('add_animal.pet_details.title_field'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: t.translate('add_animal.pet_details.description_hint'),
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: _contactNameController,
                          decoration: InputDecoration(
                            labelText: t.translate('auth.name'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: _contactPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: t.translate('auth.phone'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: t.translate('add_animal.contact_info.address'),
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Text(
                              t.translate('profile.edit_report_active'),
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              activeTrackColor: AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                        SizedBox(height: 32.h),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: _saving
                              ? SizedBox(
                                  height: 24.h,
                                  width: 24.w,
                                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  t.translate('common.save'),
                                  style: TextStyle(fontSize: 16.sp),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
