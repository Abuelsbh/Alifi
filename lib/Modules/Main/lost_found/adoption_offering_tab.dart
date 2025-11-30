import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/translated_text.dart';
import '../../../Widgets/custom_card.dart';
import 'unified_pet_details_screen.dart';

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
                          return _buildPetCard(
                            context,
                            _filteredPets[index],
                            index % 2 == 0 ? ThemeClass.of(context).secondaryColor : ThemeClass.of(context).primaryColor,
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

  Widget _buildPetCard(BuildContext context, AdoptionPetModel pet, Color color) {
    final imageUrls = pet.photos;

    return CustomCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedPetDetailsScreen(
              type: PetDetailsType.adoption,
              adoptionPet: pet,
            ),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Base Card
          Container(
            width: double.infinity,
            height: 85.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                bottomRight: Radius.circular(24.r),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 130.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pet Name
                    Text(
                      pet.petName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Pet Type, Gender, Age
                    Text(
                      '${pet.petType} • ${pet.gender} • ${pet.age} سنة',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color == ThemeClass.of(context).primaryColor
                      ? ThemeClass.of(context).secondaryColor
                      : ThemeClass.of(context).primaryColor,
                  size: 18.sp,
                ),
              ],
            ),
          ),

          // Positioned Pet Image
          Positioned(
            top: 6.h,
            left: 16.w,
            child: Container(
              height: 93.h,
              width: 121.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
                color: Colors.grey[300],
              ),
              child: imageUrls.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrls.first,
                  fit: BoxFit.cover,
                  memCacheWidth: 121.w.toInt(),
                  memCacheHeight: 83.h.toInt(),
                  maxWidthDiskCache: 500,
                  maxHeightDiskCache: 500,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.pets,
                    size: 40.sp,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              )
                  : Icon(
                Icons.pets,
                size: 40.sp,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

