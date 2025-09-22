import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Utilities/dialog_helper.dart';
import '../../../Utilities/text_style_helper.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../Widgets/login_widget.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/translated_text.dart';
import '../../../Widgets/custom_card.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../add_animal/add_animal_screen.dart';
import '../home/home_screen.dart';
import 'breeding_pet_details_screen.dart';

class BreedingPetsScreen extends StatefulWidget {
  const BreedingPetsScreen({super.key});

  @override
  State<BreedingPetsScreen> createState() => _BreedingPetsScreenState();
}

class _BreedingPetsScreenState extends State<BreedingPetsScreen> {
  List<BreedingPetModel> _breedingPets = [];
  bool _isLoading = true;
  String _selectedFilter = 'الكل'; // All, Dog, Cat, etc.

  final List<String> _filterOptions = ['الكل', 'كلب', 'قط', 'أخرى'];

  @override
  void initState() {
    super.initState();
    _loadBreedingPets();
  }

  Future<void> _loadBreedingPets() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Listen to real-time updates
      PetReportsService.getBreedingPetsStream().listen((pets) {
        if (mounted) {
          setState(() {
            _breedingPets = pets;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading breeding pets: $e');
      setState(() {
        _breedingPets = []; // Empty list if error
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
              onPressed: _loadBreedingPets,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: TranslatedText('breeding.title'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
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
                    selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryGreen,
                  ),
                );
              },
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredPets().isEmpty
                    ? _buildEmptyState()
                    : _buildPetsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (AuthService.isAuthenticated) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddAnimalScreen(
                  reportType: ReportType.breeding,
                  title: 'إضافة حيوان للتزاوج',
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
        child: const Icon(Icons.add, color: Colors.white),
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
            color: AppTheme.primaryGreen.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          TranslatedText(
            'breeding.no_pets_available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 8.h),
          TranslatedText(
            'breeding.no_pets_subtitle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _loadBreedingPets,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: TranslatedText('common.refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    final filteredPets = _getFilteredPets();
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredPets.length,
      itemBuilder: (context, index) {
        final pet = filteredPets[index];
        return _buildPetCard(context,pet,index%2 == 0 ? ThemeClass.of(context).secondaryColor : ThemeClass.of(context).primaryColor);
      },
    );
  }

  Widget _buildPetCard(BuildContext context, BreedingPetModel pet, Color color) {
    final imageUrls = pet.photos;

    return CustomCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BreedingPetDetailsScreen(pet: pet),
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

                // Pet Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pet.petName,
                              style: TextStyleHelper.of(context).s22RegTextStyle.copyWith(
                                color: ThemeClass.of(context).backGroundColor,
                              ),
                            ),
                          ),
                          if (pet.isRegistered)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'مسجل',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),

                      // Type • Breed • Age
                      Text(
                        pet.petType,
                        style: TextStyleHelper.of(context).s12RegTextStyle.copyWith(
                          color: ThemeClass.of(context).backGroundColor,
                        ),
                      ),
                    ],
                  ),
                ),

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

          // Pet Image
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
                child: Image.network(
                  imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
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


  List<BreedingPetModel> _getFilteredPets() {
    if (_selectedFilter == 'الكل') {
      return _breedingPets;
    }
    return _breedingPets.where((pet) => pet.petType == _selectedFilter).toList();
  }
} 