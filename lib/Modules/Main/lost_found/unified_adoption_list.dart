import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Models/pet_report_model.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../Widgets/translated_text.dart';
import '../../../core/services/auth_service.dart';
import 'unified_pet_card.dart';

/// All adoption listings (seeking + offering) in one list, newest first.
class UnifiedAdoptionList extends StatefulWidget {
  const UnifiedAdoptionList({super.key});

  @override
  State<UnifiedAdoptionList> createState() => _UnifiedAdoptionListState();
}

class _UnifiedAdoptionListState extends State<UnifiedAdoptionList> {
  List<AdoptionPetModel> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('adoption_pets').limit(80).get();

      final isAdmin = AuthService.isAdmin;
      final activeDocs = querySnapshot.docs.where((doc) {
        try {
          final data = doc.data();
          if (data['isActive'] != true) return false;
          if (!isAdmin) {
            final approvalStatus = data['approvalStatus'];
            return approvalStatus == 'approved';
          }
          return true;
        } catch (_) {
          return false;
        }
      }).toList();

      activeDocs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final aTime =
            (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      final pets = <AdoptionPetModel>[];
      for (final doc in activeDocs) {
        try {
          pets.add(AdoptionPetModel.fromFirestore(doc));
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _pets = pets;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pets = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 64.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 16.h),
            TranslatedText(
              'adoption.no_pets_all',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            SizedBox(height: 8.h),
            TranslatedText(
              'adoption.no_pets_all_subtitle',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _pets.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: UnifiedPetCard(
              adoptionPet: _pets[index],
              color: index % 2 == 0
                  ? ThemeClass.of(context).secondaryColor
                  : ThemeClass.of(context).primaryColor,
              reportType: 'adoption',
            ),
          );
        },
      ),
    );
  }
}
