import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../core/services/auth_service.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/translated_text.dart';
import 'unified_pet_card.dart';

class AdoptionOfferingTab extends StatefulWidget {
  const AdoptionOfferingTab({super.key});

  @override
  State<AdoptionOfferingTab> createState() => _AdoptionOfferingTabState();
}

class _AdoptionOfferingTabState extends State<AdoptionOfferingTab> {
  List<AdoptionPetModel> _adoptionPets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdoptionPets();
  }

  Future<void> _loadAdoptionPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('adoption_pets')
          .limit(50)
          .get();

      // Filter and sort manually
      final isAdmin = AuthService.isAdmin;
      final activeDocs = querySnapshot.docs.where((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isActive'] != true) return false;
          // Filter by adoptionType = 'offering'
          final adoptionType = data['adoptionType'] ?? 'offering'; // Default to offering for backward compatibility
          if (adoptionType != 'offering') return false;
          // Admin can see all, regular users only see approved
          if (!isAdmin) {
            final approvalStatus = data['approvalStatus'];
            return approvalStatus == 'approved';
          }
          return true; // Admin sees all (pending + approved)
        } catch (e) {
          print('Error filtering doc ${doc.id}: $e');
          return false;
        }
      }).toList();

      // Sort by createdAt manually
      activeDocs.sort((a, b) {
        try {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        } catch (e) {
          print('Error sorting docs: $e');
          return 0;
        }
      });

      // Convert to models with error handling
      final pets = <AdoptionPetModel>[];
      for (final doc in activeDocs) {
        try {
          final pet = AdoptionPetModel.fromFirestore(doc);
          pets.add(pet);
        } catch (e) {
          print('Error converting doc ${doc.id} to AdoptionPetModel: $e');
        }
      }
      
      setState(() {
        _adoptionPets = pets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading adoption pets: $e');
      setState(() {
        _adoptionPets = [];
        _isLoading = false;
      });
    }
  }

  List<AdoptionPetModel> get _filteredPets {
    return _adoptionPets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Content Section
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPets.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAdoptionPets,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: _filteredPets.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: UnifiedPetCard(
                              adoptionPet: _filteredPets[index],
                              color: index % 2 == 0 ? ThemeClass.of(context).secondaryColor : ThemeClass.of(context).primaryColor,
                              reportType: 'adoption',
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: 24.h),
          TranslatedText(
            'adoption.no_offering_pets',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 16.h),
          TranslatedText(
            'adoption.no_offering_pets_subtitle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

