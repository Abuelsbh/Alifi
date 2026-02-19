import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/custom_card.dart';
import '../lost_found/unified_pet_details_screen.dart';
import 'edit_report_screen.dart';

class MyAnimalsScreen extends StatefulWidget {
  const MyAnimalsScreen({super.key});

  @override
  State<MyAnimalsScreen> createState() => _MyAnimalsScreenState();
}

class _MyAnimalsScreenState extends State<MyAnimalsScreen> {
  int _streamKey = 0;

  void _retry() => setState(() => _streamKey++);

  void _openDetails(Map<String, dynamic> animal) {
    final type = animal['type'] as String? ?? '';
    final id = animal['id'] as String? ?? '';

    if (type == 'lost' || type == 'found') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedPetDetailsScreen(
            type: PetDetailsType.report,
            report: animal,
          ),
        ),
      );
      return;
    }
    if (type == 'adoption') {
      try {
        final model = AdoptionPetModel.fromFirestoreMap(id, animal);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedPetDetailsScreen(
              type: PetDetailsType.adoption,
              adoptionPet: model,
            ),
          ),
        );
      } catch (e) {
        _showError('${context.read<AppLanguage>().translate('profile.my_animals_load_error') ?? 'Error loading'} $e');
      }
      return;
    }
    if (type == 'breeding') {
      try {
        final model = BreedingPetModel.fromFirestoreMap(id, animal);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedPetDetailsScreen(
              type: PetDetailsType.breeding,
              breedingPet: model,
            ),
          ),
        );
      } catch (e) {
        _showError('${context.read<AppLanguage>().translate('profile.my_animals_load_error') ?? 'Error loading'} $e');
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  void _deleteAnimal(Map<String, dynamic> animal) async {
    final t = context.read<AppLanguage>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.translate('profile.my_animals_delete_title') ?? 'Delete'),
        content: Text(t.translate('profile.my_animals_delete_confirm') ?? 'Delete this animal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.translate('common.cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.translate('common.delete') ?? 'Delete', style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final collection = animal['collection'] as String? ?? '';
      final id = animal['id'] as String? ?? '';
      if (collection.isEmpty || id.isEmpty) throw Exception('Invalid animal');
      await PetReportsService.deleteReport(reportId: id, collection: collection);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.translate('profile.my_animals_deleted') ?? 'Deleted'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      _showError('${t.translate('profile.my_animals_delete_error') ?? 'Delete failed'}: $e');
    }
  }

  void _showOptions(Map<String, dynamic> animal) {
    final t = context.read<AppLanguage>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.visibility, color: AppTheme.primaryGreen),
                      title: Text(t.translate('profile.my_animals_view') ?? 'View'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openDetails(animal);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.edit, color: AppTheme.primaryGreen),
                      title: Text(t.translate('profile.edit') ?? 'Edit'),
                      onTap: () {
                        Navigator.pop(ctx);
                        final id = animal['id'] as String? ?? '';
                        final collection = animal['collection'] as String? ?? '';
                        final type = animal['type'] as String? ?? 'lost';
                        if (id.isEmpty || collection.isEmpty) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditReportScreen(
                              reportId: id,
                              collection: collection,
                              type: type,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.delete, color: AppTheme.error),
                      title: Text(t.translate('common.delete') ?? 'Delete', style: TextStyle(color: AppTheme.error)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _deleteAnimal(animal);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<AppLanguage>(context);
    final title = t.translate('profile.my_animals') ?? 'My Animals';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryGreen, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
          ),
        ),
        centerTitle: true,
        actions: [
          if (AuthService.isAuthenticated && AuthService.userId != null)
            IconButton(
              onPressed: _retry,
              icon: Icon(Icons.refresh, color: AppTheme.primaryGreen, size: 22.sp),
              tooltip: t.translate('common.retry') ?? 'Refresh',
            ),
        ],
      ),
      body: !AuthService.isAuthenticated || AuthService.userId == null
          ? _buildEmpty(t)
          : StreamBuilder<List<Map<String, dynamic>>>(
              key: ValueKey<int>(_streamKey),
              stream: PetReportsService.getUserAllAnimalsStream(AuthService.userId!),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _buildError(t, snap.error, _retry);
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final animals = snap.data ?? [];
                if (animals.isEmpty) return _buildEmpty(t);
                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: animals.length,
                  itemBuilder: (context, i) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _AnimalCard(
                      animal: animals[i],
                      onTap: () => _openDetails(animals[i]),
                      onOptions: () => _showOptions(animals[i]),
                      t: t,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmpty(AppLanguage t) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64.sp, color: Colors.grey.shade400),
            SizedBox(height: 16.h),
            Text(
              t.translate('profile.my_animals_empty') ?? 'No animals yet',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              t.translate('profile.my_animals_empty_subtitle') ?? 'Animals you add will appear here.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(AppLanguage t, Object? error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppTheme.error),
            SizedBox(height: 16.h),
            Text(
              t.translate('profile.my_animals_error') ?? 'Error loading animals',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              error?.toString() ?? '',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 24.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(t.translate('common.retry') ?? 'Retry'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  final Map<String, dynamic> animal;
  final VoidCallback onTap;
  final VoidCallback onOptions;
  final AppLanguage t;

  const _AnimalCard({
    required this.animal,
    required this.onTap,
    required this.onOptions,
    required this.t,
  });

  String get _name {
    try {
      final type = animal['type'] as String? ?? '';
      
      // Check title first (for adoption and reports that might have title)
      final title = animal['title']?.toString()?.trim() ?? '';
      if (title.isNotEmpty) {
        return title;
      }
      
      // Check root level name field
      final rootName = animal['name']?.toString()?.trim() ?? '';
      if (rootName.isNotEmpty) {
        return rootName;
      }
      
      if (type == 'lost' || type == 'found') {
        final pd = animal['petDetails'];
        if (pd is Map) {
          final name = pd['name']?.toString()?.trim() ?? '';
          if (name.isNotEmpty) return name;
        }
        final petName = animal['petName']?.toString()?.trim() ?? '';
        if (petName.isNotEmpty) return petName;
        return '';
      }
      
      if (type == 'adoption') {
        final pd = animal['petDetails'];
        if (pd is Map) {
          final name = pd['name']?.toString()?.trim() ?? '';
          if (name.isNotEmpty) return name;
        }
        final petName = animal['petName']?.toString()?.trim() ?? '';
        if (petName.isNotEmpty) return petName;
        return '';
      }
      
      if (type == 'breeding') {
        final pi = animal['petInfo'];
        if (pi is Map) {
          final name = pi['name']?.toString()?.trim() ?? '';
          if (name.isNotEmpty) return name;
        }
        final petName = animal['petName']?.toString()?.trim() ?? '';
        if (petName.isNotEmpty) return petName;
        return '';
      }
      
      return '';
    } catch (e) {
      print('Error getting pet name: $e');
      return '';
    }
  }

  String get _petType {
    final type = animal['type'] as String? ?? '';
    if (type == 'lost' || type == 'found') {
      final pd = animal['petDetails'] as Map? ?? {};
      return pd['type']?.toString() ?? animal['petType']?.toString() ?? '';
    }
    if (type == 'adoption') {
      final pd = animal['petDetails'] as Map? ?? {};
      return pd['type']?.toString() ?? animal['petType']?.toString() ?? '';
    }
    if (type == 'breeding') {
      final pi = animal['petInfo'] as Map? ?? {};
      return pi['type']?.toString() ?? animal['petType']?.toString() ?? '';
    }
    return '';
  }

  String get _typeLabel {
    final type = animal['type'] as String? ?? '';
    switch (type) {
      case 'lost':
        return t.translate('profile.lost_animals') ?? 'Lost';
      case 'found':
        return t.translate('profile.my_animals_found') ?? 'Found';
      case 'adoption':
        return t.translate('profile.animal_for_adoption') ?? 'Adoption';
      case 'breeding':
        return t.translate('profile.animals_for_mating') ?? 'Breeding';
      default:
        return type;
    }
  }

  Color get _typeColor {
    switch (animal['type'] as String? ?? '') {
      case 'lost':
        return AppTheme.warning;
      case 'found':
        return AppTheme.success;
      case 'adoption':
        return AppTheme.primaryOrange;
      case 'breeding':
        return AppTheme.primaryGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = animal['imageUrls'] as List<dynamic>? ?? [];
    final firstUrl = urls.isNotEmpty ? urls.first.toString() : null;

    return CustomCard(
      onTap: onTap,
      border: Border.all(color: Colors.grey.shade300, width: 1),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: Colors.grey.shade200,
              ),
              child: firstUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: CachedNetworkImage(
                        imageUrl: firstUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                        ),
                        errorWidget: (_, __, ___) => Icon(Icons.pets, size: 36.sp, color: AppTheme.primaryGreen),
                      ),
                    )
                  : Icon(Icons.pets, size: 36.sp, color: AppTheme.primaryGreen),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name.isEmpty ? (t.translate('profile.my_animals_unnamed') ?? 'Unnamed') : _name,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _petType,
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _typeLabel,
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: _typeColor),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onOptions,
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 22.sp),
            ),
          ],
        ),
      ),
    );
  }
}
