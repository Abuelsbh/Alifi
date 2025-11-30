import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'unified_pet_details_screen.dart';

class BreedingPetsScreen extends StatefulWidget {
  const BreedingPetsScreen({super.key});

  @override
  State<BreedingPetsScreen> createState() => _BreedingPetsScreenState();
}

class _BreedingPetsScreenState extends State<BreedingPetsScreen> {
  List<BreedingPetModel> _breedingPets = [];
  bool _isLoading = true;

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
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _breedingPets.isEmpty
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
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _breedingPets.length,
      itemBuilder: (context, index) {
        final pet = _breedingPets[index];
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
            builder: (context) => UnifiedPetDetailsScreen(
              type: PetDetailsType.breeding,
              breedingPet: pet,
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