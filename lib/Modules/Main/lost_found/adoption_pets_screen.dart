import 'package:alifi/Modules/Main/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../Utilities/dialog_helper.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../Widgets/login_widget.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/translated_text.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/translated_custom_button.dart';
import '../profile/simple_profile_screen.dart';
import 'unified_pet_details_screen.dart';
import '../../add_animal/add_animal_screen.dart';
import 'lost_found_screen.dart';

class AdoptionPetsScreen extends StatefulWidget {
  const AdoptionPetsScreen({super.key});

  @override
  State<AdoptionPetsScreen> createState() => _AdoptionPetsScreenState();
}

class _AdoptionPetsScreenState extends State<AdoptionPetsScreen> {
  List<AdoptionPetModel> _adoptionPets = [];
  bool _isLoading = true;
  String _selectedFilter = 'الكل';
  
  final List<String> _filterOptions = ['الكل', 'كلب', 'قط', 'طائر', 'أرنب', 'أخرى'];

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
          // Admin can see all, regular users only see approved
          if (!isAdmin) {
            final approvalStatus = data['approvalStatus'];
            // Only show approved reports - no null or pending
            return approvalStatus == 'approved';
          }
          return true; // Admin sees all (pending + approved)
        } catch (e) {
          print('Error filtering doc ${doc.id}: $e');
          return false; // Skip documents with invalid data
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
          return 0; // Keep original order if sorting fails
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
          // Skip this document and continue with others
        }
      }
      
      setState(() {
        _adoptionPets = pets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading adoption pets: $e');
      // Print additional debug info
      print('Error type: ${e.runtimeType}');
      if (e is StateError) {
        print('StateError details: ${e.message}');
      }
      
      setState(() {
        _adoptionPets = []; // Empty list if error
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات. يرجى المحاولة مرة أخرى.'),
            backgroundColor: AppTheme.error,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: _loadAdoptionPets,
            ),
          ),
        );
      }
    }
  }

  List<AdoptionPetModel> get _filteredPets {
    if (_selectedFilter == 'الكل') {
      return _adoptionPets;
    }
    return _adoptionPets.where((pet) => pet.petType == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.primaryGreen,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TranslatedText(
          'adoption.title',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppTheme.primaryGreen,
            ),
            onPressed: _loadAdoptionPets,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Theme.of(context).colorScheme.background,
                      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryGreen : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryGreen : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
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
                            return _buildPetCard(context,_filteredPets[index],index%2 == 0 ? ThemeClass.of(context).secondaryColor : ThemeClass.of(context).primaryColor);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (AuthService.isAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddAnimalScreen(
                  reportType: ReportType.adoption,
                  title: 'إضافة حيوان للتبني',
                ),
              ),
            );
          } else {
            DialogHelper.custom(context: context).customDialog(
              dialogWidget: LoginWidget(
              ),
            );
          }
        },
        backgroundColor: AppTheme.primaryGreen,
        icon: Icon(
          Icons.pets,
          color: Colors.white,
        ),
        label: TranslatedText(
          'adoption.add_pet',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
            'adoption.no_pets_available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 16.h),
          TranslatedText(
            'adoption.no_pets_subtitle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadAdoptionPets,
            icon: Icon(Icons.refresh),
            label: Text('تحديث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
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


  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inMinutes} دقيقة';
    }
  }
} 