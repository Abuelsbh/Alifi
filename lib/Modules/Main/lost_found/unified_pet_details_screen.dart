import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/translation_service.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';
import '../../../Widgets/translated_text.dart';
import '../../../Widgets/translated_custom_button.dart';

enum PetDetailsType {
  report,
  adoption,
  breeding,
}

class UnifiedPetDetailsScreen extends StatefulWidget {
  final PetDetailsType type;
  final Map<String, dynamic>? report;
  final AdoptionPetModel? adoptionPet;
  final BreedingPetModel? breedingPet;

  const UnifiedPetDetailsScreen({
    super.key,
    required this.type,
    this.report,
    this.adoptionPet,
    this.breedingPet,
  }) : assert(
          (type == PetDetailsType.report && report != null) ||
          (type == PetDetailsType.adoption && adoptionPet != null) ||
          (type == PetDetailsType.breeding && breedingPet != null),
        );

  @override
  State<UnifiedPetDetailsScreen> createState() => _UnifiedPetDetailsScreenState();
}

class _UnifiedPetDetailsScreenState extends State<UnifiedPetDetailsScreen> {
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _images {
    switch (widget.type) {
      case PetDetailsType.report:
        final imageUrls = widget.report!['imageUrls'] as List<dynamic>? ?? [];
        return imageUrls.map((e) => e.toString()).toList();
      case PetDetailsType.adoption:
        return widget.adoptionPet!.photos;
      case PetDetailsType.breeding:
        return widget.breedingPet!.photos;
    }
  }

  String get _petName {
    switch (widget.type) {
      case PetDetailsType.report:
        final petDetails = widget.report!['petDetails'] as Map<String, dynamic>? ?? {};
        return petDetails['name'] ?? TranslationService.instance.translate('pet');
      case PetDetailsType.adoption:
        return widget.adoptionPet!.petName.isNotEmpty 
            ? widget.adoptionPet!.petName 
            : TranslationService.instance.translate('pet');
      case PetDetailsType.breeding:
        return widget.breedingPet!.petName.isNotEmpty 
            ? widget.breedingPet!.petName 
            : TranslationService.instance.translate('pet');
    }
  }

  String get _description {
    switch (widget.type) {
      case PetDetailsType.report:
        return widget.report!['description'] ?? '';
      case PetDetailsType.adoption:
        return widget.adoptionPet!.description;
      case PetDetailsType.breeding:
        return widget.breedingPet!.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // _buildHeaderSection(),
                  // SizedBox(height: 24.h),
                  _buildBasicInfoSection(),
                  SizedBox(height: 24.h),
                  if (_description.isNotEmpty) ...[
                    _buildDescriptionSection(),
                    SizedBox(height: 24.h),
                  ],
                  _buildTypeSpecificSections(),
                  SizedBox(height: 24.h),
                  _buildContactSection(),
                  SizedBox(height: 32.h),
                  _buildActionButtons(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final isLost = widget.type == PetDetailsType.report && 
                   widget.report!['type'] == 'lost';
    
    Color appBarColor;
    switch (widget.type) {
      case PetDetailsType.report:
        appBarColor = isLost ? AppTheme.error : AppTheme.success;
        break;
      case PetDetailsType.adoption:
        appBarColor = AppTheme.primaryGreen;
        break;
      case PetDetailsType.breeding:
        appBarColor = AppTheme.primaryOrange;
        break;
    }

    return SliverAppBar(
      expandedHeight: 350.h,
      floating: false,
      pinned: true,
      backgroundColor: appBarColor,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.share,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          onPressed: () => _sharePet(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _petName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
            shadows: [
              Shadow(
                offset: const Offset(0, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_images.isNotEmpty)
              _buildImageCarousel()
            else
              _buildDefaultBackground(appBarColor),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دوال للتنقل بين الصور
  void _nextImage() {
    if (_currentImageIndex < _images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildImageCarousel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // الصور الرئيسية
        PageView.builder(
          controller: _pageController,
          itemCount: _images.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: _images[index],
              fit: BoxFit.cover,
              memCacheWidth: 800,
              memCacheHeight: 600,
              maxWidthDiskCache: 1920,
              maxHeightDiskCache: 1080,
              placeholder: (context, url) => Container(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              errorWidget: (context, url, error) {
                return _buildDefaultBackground(AppTheme.primaryGreen);
              },
            );
          },
        ),
        
        // GestureDetector للصورة (فقط في المنطقة الوسطى)
        if (_images.length > 1)
          Positioned(
            left: 100.w,
            right: 100.w,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _showFullScreenImage(_currentImageIndex),
              child: Container(color: Colors.transparent),
            ),
          )
        else
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _showFullScreenImage(_currentImageIndex),
              child: Container(color: Colors.transparent),
            ),
          ),
        
        // عداد الصور في الأعلى
        if (_images.length > 1)
          Positioned(
            top: 50.h,
            right: 16.w,
            child: IgnorePointer(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${_images.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        
        // مؤشرات الصور في الأسفل
        if (_images.length > 1)
          Positioned(
            bottom: 20.h,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _images.length,
                  (index) => Container(
                    width: _currentImageIndex == index ? 24.w : 8.w,
                    height: 8.h,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: _currentImageIndex == index 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        // أزرار التنقل - في المقدمة تماماً
        if (_images.length > 1) ...[
          // زر السابق
          Positioned(
            left: 16.w,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _previousImage,
                  borderRadius: BorderRadius.circular(25.r),
                  child: Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 30.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // زر التالي
          Positioned(
            right: 16.w,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _nextImage,
                  borderRadius: BorderRadius.circular(25.r),
                  child: Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 30.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultBackground(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 100.sp,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    String typeLabel;
    Color typeColor;
    IconData typeIcon;

    switch (widget.type) {
      case PetDetailsType.report:
        final isLost = widget.report!['type'] == 'lost';
        typeLabel = isLost 
            ? TranslationService.instance.translate('lost')
            : TranslationService.instance.translate('found');
        typeColor = isLost ? AppTheme.error : AppTheme.success;
        typeIcon = isLost ? Icons.search : Icons.check_circle;
        break;
      case PetDetailsType.adoption:
        typeLabel = TranslationService.instance.translate('adoption');
        typeColor = AppTheme.primaryGreen;
        typeIcon = Icons.favorite;
        break;
      case PetDetailsType.breeding:
        typeLabel = TranslationService.instance.translate('breeding');
        typeColor = AppTheme.primaryOrange;
        typeIcon = Icons.family_restroom;
        break;
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withOpacity(0.1),
            typeColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: typeColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              typeIcon,
              color: typeColor,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _petName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (_images.length > 1)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library,
                    size: 16.sp,
                    color: typeColor,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${_images.length}',
                    style: TextStyle(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    Map<String, String> basicInfo = {};

    switch (widget.type) {
      case PetDetailsType.report:
        final petDetails = widget.report!['petDetails'] as Map<String, dynamic>? ?? {};
        if (petDetails['type'] != null) {
          basicInfo[TranslationService.instance.translate('type')] = petDetails['type'];
        }
        if (petDetails['breed'] != null) {
          basicInfo[TranslationService.instance.translate('breed')] = petDetails['breed'];
        }
        if (petDetails['age'] != null) {
          basicInfo[TranslationService.instance.translate('age')] = petDetails['age'].toString();
        }
        if (petDetails['gender'] != null) {
          basicInfo[TranslationService.instance.translate('gender')] = petDetails['gender'];
        }
        if (petDetails['color'] != null) {
          basicInfo[TranslationService.instance.translate('color')] = petDetails['color'];
        }
        if (petDetails['size'] != null) {
          basicInfo[TranslationService.instance.translate('size')] = petDetails['size'];
        }
        break;
      case PetDetailsType.adoption:
        final pet = widget.adoptionPet!;
        if (pet.petType.isNotEmpty) {
          basicInfo[TranslationService.instance.translate('type')] = pet.petType;
        }
        if (pet.breed.isNotEmpty) {
          basicInfo[TranslationService.instance.translate('breed')] = pet.breed;
        }
        if (pet.age > 0) {
          basicInfo[TranslationService.instance.translate('age')] = '${pet.age} ${TranslationService.instance.translate('years')}';
        }
        if (pet.gender.isNotEmpty) {
          basicInfo[TranslationService.instance.translate('gender')] = pet.gender;
        }
        if (pet.color.isNotEmpty) {
          basicInfo[TranslationService.instance.translate('color')] = pet.color;
        }
        if (pet.weight > 0) {
          basicInfo[TranslationService.instance.translate('weight')] = '${pet.weight} ${TranslationService.instance.translate('kg')}';
        }
        break;
      case PetDetailsType.breeding:
        final pet = widget.breedingPet!;
        if (pet.petType.isNotEmpty) {
          basicInfo[TranslationService.instance.translate('type')] = pet.petType;
        }
        if (pet.breed.isNotEmpty) {
          basicInfo[TranslationService.instance.translate('breed')] = pet.breed;
        }
        if (pet.age > 0) {
          basicInfo[TranslationService.instance.translate('age')] = '${pet.age} ${TranslationService.instance.translate('years')}';
        }
        if (pet.gender.isNotEmpty) {
          basicInfo[TranslationService.instance.translate('gender')] = pet.gender;
        }
        if (pet.color.isNotEmpty) {
          basicInfo[TranslationService.instance.translate('color')] = pet.color;
        }
        if (pet.weight > 0) {
          basicInfo[TranslationService.instance.translate('weight')] = '${pet.weight} ${TranslationService.instance.translate('kg')}';
        }
        break;
    }

    if (basicInfo.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryGreen,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  TranslationService.instance.translate('pet_details'),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ...basicInfo.entries.map((entry) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Container(
                    width: 100.w,
                    child: Text(
                      '${entry.key}:',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.description,
                    color: AppTheme.primaryOrange,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  TranslationService.instance.translate('description'),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              _description,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificSections() {
    switch (widget.type) {
      case PetDetailsType.report:
        return _buildReportSpecificSections();
      case PetDetailsType.adoption:
        return _buildAdoptionSpecificSections();
      case PetDetailsType.breeding:
        return _buildBreedingSpecificSections();
    }
  }

  Widget _buildReportSpecificSections() {
    final report = widget.report!;
    final location = report['location'] as Map<String, dynamic>? ?? {};
    final contactInfo = report['contactInfo'] as Map<String, dynamic>? ?? {};
    final petDetails = report['petDetails'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        if (location['address'] != null || location['coordinates'] != null) ...[
          _buildLocationCard(location),
          SizedBox(height: 16.h),
        ],
        if (petDetails['distinguishingMarks'] != null) ...[
          _buildInfoCard(
            TranslationService.instance.translate('distinguishing_marks'),
            petDetails['distinguishingMarks'],
            Icons.visibility,
            AppTheme.primaryGreen,
          ),
          SizedBox(height: 16.h),
        ],
        if (report['reward'] != null) ...[
          _buildRewardCard(report['reward']),
          SizedBox(height: 16.h),
        ],
      ],
    );
  }

  Widget _buildAdoptionSpecificSections() {
    final pet = widget.adoptionPet!;
    final sections = <Widget>[];

    if (pet.adoptionFee > 0) {
      sections.add(_buildFeeCard(
        TranslationService.instance.translate('adoption_fee'),
        '${pet.adoptionFee.toStringAsFixed(0)} ${TranslationService.instance.translate('currency')}',
        AppTheme.primaryGreen,
      ));
      sections.add(SizedBox(height: 16.h));
    }

    if (pet.isVaccinated || pet.isNeutered || pet.goodWithKids || pet.goodWithPets) {
      sections.add(_buildFeaturesSection(pet));
      sections.add(SizedBox(height: 16.h));
    }

    if (pet.healthStatus.isNotEmpty || pet.microchipId.isNotEmpty) {
      sections.add(_buildHealthCard(pet));
      sections.add(SizedBox(height: 16.h));
    }

    if (pet.address.isNotEmpty) {
      sections.add(_buildLocationCard({'address': pet.address}));
      sections.add(SizedBox(height: 16.h));
    }

    return Column(children: sections);
  }

  Widget _buildBreedingSpecificSections() {
    final pet = widget.breedingPet!;
    final sections = <Widget>[];

    if (pet.breedingFee > 0) {
      sections.add(_buildFeeCard(
        TranslationService.instance.translate('breeding_fee'),
        '${pet.breedingFee.toStringAsFixed(0)} ${TranslationService.instance.translate('currency')}',
        AppTheme.primaryOrange,
      ));
      sections.add(SizedBox(height: 16.h));
    }

    if (pet.isRegistered || pet.hasBreedingExperience) {
      sections.add(_buildBreedingFeaturesSection(pet));
      sections.add(SizedBox(height: 16.h));
    }

    if (pet.breedingGoals.isNotEmpty || pet.availabilityPeriod.isNotEmpty) {
      sections.add(_buildBreedingInfoCard(pet));
      sections.add(SizedBox(height: 16.h));
    }

    if (pet.address.isNotEmpty) {
      sections.add(_buildLocationCard({'address': pet.address}));
      sections.add(SizedBox(height: 16.h));
    }

    return Column(children: sections);
  }

  Widget _buildFeaturesSection(AdoptionPetModel pet) {
    final features = <Widget>[];
    
    if (pet.isVaccinated) {
      features.add(_buildFeatureChip('مُطعّم', Icons.medical_services, Colors.green));
    }
    if (pet.isNeutered) {
      features.add(_buildFeatureChip('مُعقّم', Icons.medical_services, Colors.blue));
    }
    if (pet.goodWithKids) {
      features.add(_buildFeatureChip('ودود مع الأطفال', Icons.child_care, Colors.orange));
    }
    if (pet.goodWithPets) {
      features.add(_buildFeatureChip('ودود مع الحيوانات', Icons.pets, Colors.purple));
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.instance.translate('features'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: features,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedingFeaturesSection(BreedingPetModel pet) {
    final features = <Widget>[];
    
    if (pet.isRegistered) {
      features.add(_buildFeatureChip('مسجّل', Icons.verified, AppTheme.primaryOrange));
    }
    if (pet.hasBreedingExperience) {
      features.add(_buildFeatureChip('لديه خبرة', Icons.star, Colors.blue));
    }
    if (pet.willTravel) {
      features.add(_buildFeatureChip('يقبل السفر', Icons.directions_car, Colors.purple));
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.instance.translate('features'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: features,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(AdoptionPetModel pet) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: AppTheme.primaryGreen, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  TranslationService.instance.translate('health_status'),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (pet.healthStatus.isNotEmpty)
              _buildInfoRow('الحالة الصحية', pet.healthStatus),
            if (pet.microchipId.isNotEmpty) ...[
              SizedBox(height: 8.h),
              _buildInfoRow('رقم الشريحة', pet.microchipId),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreedingInfoCard(BreedingPetModel pet) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: AppTheme.primaryOrange, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  TranslationService.instance.translate('breeding_information'),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (pet.breedingGoals.isNotEmpty)
              _buildInfoRow('أهداف التزاوج', pet.breedingGoals),
            if (pet.availabilityPeriod.isNotEmpty) ...[
              SizedBox(height: 8.h),
              _buildInfoRow('فترة التوفر', pet.availabilityPeriod),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    final address = location['address'] ?? '';
    if (address.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppTheme.primaryGreen,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  TranslationService.instance.translate('location'),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              address,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              content,
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeCard(String title, String amount, Color color) {
    return CustomCard(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_money,
                color: color,
                size: 28.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(dynamic reward) {
    return CustomCard(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.warning.withOpacity(0.1),
              AppTheme.warning.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on,
                color: AppTheme.warning,
                size: 28.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.instance.translate('reward_for_finding'),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$reward ${TranslationService.instance.translate('currency')}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    String contactName = '';
    String contactPhone = '';
    String contactEmail = '';

    switch (widget.type) {
      case PetDetailsType.report:
        final contactInfo = widget.report!['contactInfo'] as Map<String, dynamic>? ?? {};
        contactName = contactInfo['name'] ?? widget.report!['userId'] ?? '';
        contactPhone = contactInfo['phone'] ?? '';
        contactEmail = contactInfo['email'] ?? '';
        break;
      case PetDetailsType.adoption:
        final pet = widget.adoptionPet!;
        contactName = pet.contactName;
        contactPhone = pet.contactPhone;
        contactEmail = pet.contactEmail;
        break;
      case PetDetailsType.breeding:
        final pet = widget.breedingPet!;
        contactName = pet.contactName;
        contactPhone = pet.contactPhone;
        contactEmail = pet.contactEmail;
        break;
    }

    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.contact_phone,
                    color: AppTheme.primaryOrange,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  TranslationService.instance.translate('contact_information'),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            if (contactName.isNotEmpty) ...[
              _buildContactRow(Icons.person, contactName),
              SizedBox(height: 12.h),
            ],
            if (contactPhone.isNotEmpty) ...[
              _buildContactRow(Icons.phone, contactPhone),
              SizedBox(height: 12.h),
            ],
            if (contactEmail.isNotEmpty)
              _buildContactRow(Icons.email, contactEmail),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: AppTheme.primaryOrange,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    String contactPhone = '';

    switch (widget.type) {
      case PetDetailsType.report:
        final contactInfo = widget.report!['contactInfo'] as Map<String, dynamic>? ?? {};
        contactPhone = contactInfo['phone'] ?? '';
        break;
      case PetDetailsType.adoption:
        contactPhone = widget.adoptionPet!.contactPhone;
        break;
      case PetDetailsType.breeding:
        contactPhone = widget.breedingPet!.contactPhone;
        break;
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: TranslationService.instance.translate('contact_owner'),
            onPressed: () => _makePhoneCall(contactPhone),
            backgroundColor: AppTheme.primaryGreen,
            textColor: Colors.white,
            icon: Icons.phone,
            height: 56.h,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: TranslationService.instance.translate('whatsapp'),
                onPressed: () => _sendWhatsApp(contactPhone),
                backgroundColor: Colors.green,
                textColor: Colors.white,
                icon: Icons.chat,
                height: 56.h,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: CustomButton(
                text: TranslationService.instance.translate('share'),
                onPressed: () => _sharePet(),
                backgroundColor: AppTheme.primaryOrange,
                textColor: Colors.white,
                icon: Icons.share,
                height: 56.h,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showFullScreenImage(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageView(
          images: _images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.instance.translate('contact_info_unavailable'))),
      );
      return;
    }

    final url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TranslationService.instance.translate('cannot_make_call'))),
        );
      }
    }
  }

  Future<void> _sendWhatsApp(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.instance.translate('contact_info_unavailable'))),
      );
      return;
    }

    final message = TranslationService.instance.translate('whatsapp_message').replaceAll('{0}', _petName);
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TranslationService.instance.translate('cannot_open_whatsapp'))),
        );
      }
    }
  }

  void _sharePet() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(TranslationService.instance.translate('share_feature_coming_soon'))),
    );
  }
}

class _FullScreenImageView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageView({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    maxWidthDiskCache: 2048,
                    maxHeightDiskCache: 2048,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 64),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // أزرار التنقل في شاشة العرض الكامل
          if (widget.images.length > 1) ...[
            // زر السابق
            Positioned(
              left: 20.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_currentIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(30.r),
                    child: Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // زر التالي
            Positioned(
              right: 20.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_currentIndex < widget.images.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(30.r),
                    child: Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          // مؤشرات الصور في الأسفل
          if (widget.images.length > 1)
            Positioned(
              bottom: 30.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    width: _currentIndex == index ? 24.w : 8.w,
                    height: 8.h,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: _currentIndex == index 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

