import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/translated_text.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/translated_custom_button.dart';
import '../../../core/Language/translation_service.dart';

class BreedingPetDetailsScreen extends StatefulWidget {
  final BreedingPetModel pet;

  const BreedingPetDetailsScreen({
    super.key,
    required this.pet,
  });

  @override
  State<BreedingPetDetailsScreen> createState() => _BreedingPetDetailsScreenState();
}

class _BreedingPetDetailsScreenState extends State<BreedingPetDetailsScreen> {
  int _currentImageIndex = 0;
  PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('=== BreedingPetDetailsScreen Debug ===');
    print('Pet Name: ${widget.pet.petName}');
    print('Pet Type: ${widget.pet.petType}');
    print('Pet Age: ${widget.pet.age}');
    print('Pet Photos Count: ${widget.pet.photos.length}');
    print('Pet Photos List: ${widget.pet.photos}');
    print('Pet Breeding Fee: ${widget.pet.breedingFee}');
    print('Pet Is Registered: ${widget.pet.isRegistered}');
    print('========================================');
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Images
          SliverAppBar(
            expandedHeight: 300.h,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: widget.pet.petName.isNotEmpty 
                ? Text(
                    widget.pet.petName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  )
                : TranslatedText(
                    'breeding.pet_details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
            centerTitle: true,
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
            flexibleSpace: FlexibleSpaceBar(
              background: widget.pet.photos.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemCount: widget.pet.photos.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              widget.pet.photos[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  (loadingProgress.expectedTotalBytes ?? 1)
                                              : null,
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'جاري تحميل الصورة...',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.primaryGreen.withOpacity(0.1),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.pets,
                                        size: 80.sp,
                                        color: AppTheme.primaryGreen,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'صورة غير متاحة',
                                        style: TextStyle(
                                          color: AppTheme.primaryGreen,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        if (widget.pet.photos.length > 1) ...[
                          // Image Indicators
                          Positioned(
                            bottom: 16.h,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: widget.pet.photos.asMap().entries.map((entry) {
                                return Container(
                                  width: 8.w,
                                  height: 8.h,
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == entry.key
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Container(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pets,
                            size: 80.sp,
                            color: AppTheme.primaryGreen,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'لا توجد صور',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          
          // Pet Details
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet Name and Basic Info
                  _buildBasicInfoSection(),
                  
                  SizedBox(height: 24.h),
                  
                  // Quick Features
                  _buildQuickFeaturesSection(),
                  
                  // Description (only if not empty)
                  if (widget.pet.description.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _buildDescriptionSection(),
                  ],
                  
                  // Breeding Info
                  SizedBox(height: 24.h),
                  _buildBreedingInfoSection(),
                  
                  // Health & Care Info (only if has health info)
                  if (_hasHealthInfo()) ...[
                    SizedBox(height: 24.h),
                    _buildHealthCareSection(),
                  ],
                  
                  // Registration & Certifications
                  if (_hasRegistrationInfo()) ...[
                    SizedBox(height: 24.h),
                    _buildRegistrationSection(),
                  ],
                  
                  // Breeding Experience
                  if (_hasBreedingExperience()) ...[
                    SizedBox(height: 24.h),
                    _buildBreedingExperienceSection(),
                  ],
                  
                  // Contact Info
                  SizedBox(height: 24.h),
                  _buildContactSection(),
                  
                  SizedBox(height: 32.h),
                  
                  // Action Buttons
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

  Widget _buildBasicInfoSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.pet.petName.isNotEmpty ? widget.pet.petName : 'اسم غير محدد',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                if (widget.pet.breedingFee > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${widget.pet.breedingFee.toStringAsFixed(0)} ج.م',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: TranslatedText(
                      'breeding.free',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            Row(
              children: [
                if (widget.pet.petType.isNotEmpty) ...[
                  _buildInfoItem(Icons.category, widget.pet.petType),
                  SizedBox(width: 16.w),
                ],
                if (widget.pet.age > 0) ...[
                  _buildInfoItem(Icons.cake, '${widget.pet.age} ${TranslationService.instance.translate('breeding.years')}'),
                  SizedBox(width: 16.w),
                ],
                if (widget.pet.gender.isNotEmpty)
                  _buildInfoItem(Icons.wc, widget.pet.gender),
              ],
            ),
            
            if (widget.pet.breed.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _buildInfoItem(Icons.pets, widget.pet.breed),
            ],
            
            if (widget.pet.color.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _buildInfoItem(Icons.palette, widget.pet.color),
            ],
            
            if (widget.pet.weight > 0) ...[
              SizedBox(height: 12.h),
              _buildInfoItem(Icons.monitor_weight, '${widget.pet.weight} ${TranslationService.instance.translate('breeding.kg')}'),
            ],
            
            if (widget.pet.address.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.pet.address,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        SizedBox(width: 4.w),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickFeaturesSection() {
    final features = <Widget>[];
    
    if (widget.pet.isVaccinated) {
      features.add(_buildFeatureChip('breeding.vaccinated', Icons.medical_services, Colors.green));
    }
    if (widget.pet.isRegistered) {
      features.add(_buildFeatureChip('breeding.registered', Icons.verified, Colors.orange));
    }
    if (widget.pet.hasBreedingExperience) {
      features.add(_buildFeatureChip('breeding.experienced', Icons.star, Colors.blue));
    }
    if (widget.pet.willTravel) {
      features.add(_buildFeatureChip('breeding.will_travel', Icons.directions_car, Colors.purple));
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'breeding.features',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
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

  Widget _buildFeatureChip(String translationKey, IconData icon, Color color) {
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
          Icon(
            icon,
            size: 16.sp,
            color: color,
          ),
          SizedBox(width: 6.w),
          TranslatedText(
            translationKey,
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

  Widget _buildDescriptionSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'breeding.description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              widget.pet.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedingInfoSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'breeding.breeding_information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 16.h),
            
            if (widget.pet.breedingGoals.isNotEmpty) ...[
              _buildBreedingItem('breeding.breeding_goals', widget.pet.breedingGoals, Icons.flag),
              SizedBox(height: 12.h),
            ],
            
            if (widget.pet.availabilityPeriod.isNotEmpty) ...[
              _buildBreedingItem('breeding.availability_period', widget.pet.availabilityPeriod, Icons.schedule),
              SizedBox(height: 12.h),
            ],
            
            if (widget.pet.maxTravelDistance > 0) ...[
              _buildBreedingItem('breeding.travel_distance', '${widget.pet.maxTravelDistance} كم', Icons.location_on),
              SizedBox(height: 12.h),
            ],
            
            if (widget.pet.offspring.isNotEmpty) ...[
              _buildBreedingItem('breeding.offspring_plans', widget.pet.offspring, Icons.family_restroom),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreedingItem(String labelKey, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: AppTheme.primaryGreen,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                labelKey,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthCareSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'breeding.health_care',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 16.h),
            if (widget.pet.healthStatus.isNotEmpty)
              _buildHealthItem('breeding.health_status', widget.pet.healthStatus, Icons.favorite),
            if (widget.pet.temperament.isNotEmpty) ...[
              if (widget.pet.healthStatus.isNotEmpty) SizedBox(height: 12.h),
              _buildHealthItem('breeding.temperament', widget.pet.temperament, Icons.mood),
            ],
            if (widget.pet.specialRequirements.isNotEmpty) ...[
              if (widget.pet.healthStatus.isNotEmpty || widget.pet.temperament.isNotEmpty) SizedBox(height: 12.h),
              _buildHealthItem('breeding.special_requirements', widget.pet.specialRequirements, Icons.medical_information),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String labelKey, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: AppTheme.primaryGreen,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                labelKey,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'breeding.registration_certifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 16.h),
            
            if (widget.pet.registrationNumber.isNotEmpty) ...[
              _buildRegistrationItem('breeding.registration_number', widget.pet.registrationNumber, Icons.card_membership),
              SizedBox(height: 12.h),
            ],
            
            if (widget.pet.certifications.isNotEmpty) ...[
              _buildRegistrationItem('breeding.certifications', widget.pet.certifications.join(', '), Icons.verified_user),
              SizedBox(height: 12.h),
            ],
            
            if (widget.pet.veterinarianContact.isNotEmpty) ...[
              _buildRegistrationItem('breeding.veterinarian_contact', widget.pet.veterinarianContact, Icons.local_hospital),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationItem(String labelKey, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: AppTheme.primaryGreen,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                labelKey,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreedingExperienceSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'breeding.breeding_experience',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 16.h),
            
            if (widget.pet.breedingHistory.isNotEmpty) ...[
              _buildExperienceItem('breeding.breeding_history', widget.pet.breedingHistory, Icons.history),
              SizedBox(height: 12.h),
            ],
            
            if (widget.pet.previousOffspring.isNotEmpty) ...[
              TranslatedText(
                'breeding.previous_offspring',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 60.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.pet.previousOffspring.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          widget.pet.previousOffspring[index],
                          width: 60.w,
                          height: 60.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60.w,
                              height: 60.h,
                              color: Colors.grey[200],
                              child: Icon(Icons.pets, size: 30.sp),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceItem(String labelKey, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: AppTheme.primaryGreen,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                labelKey,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'breeding.contact_information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 20.sp,
                  color: AppTheme.primaryGreen,
                ),
                SizedBox(width: 12.w),
                Text(
                  widget.pet.contactName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 20.sp,
                  color: AppTheme.primaryGreen,
                ),
                SizedBox(width: 12.w),
                Text(
                  widget.pet.contactPhone,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (widget.pet.contactEmail.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.email,
                    size: 20.sp,
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      widget.pet.contactEmail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${TranslationService.instance.translate('breeding.posted_on').replaceAll('{0}', _formatDate(widget.pet.createdAt))}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: TranslatedCustomButton(
            textKey: 'breeding.contact_owner',
            icon: Icons.call,
            type: ButtonType.primary,
            onPressed: () => _makePhoneCall(widget.pet.contactPhone),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: TranslatedCustomButton(
                textKey: 'breeding.send_whatsapp',
                icon: Icons.chat,
                type: ButtonType.secondary,
                onPressed: () => _sendWhatsApp(widget.pet.contactPhone),
              ),
            ),
            if (widget.pet.contactEmail.isNotEmpty) ...[
              SizedBox(width: 12.w),
              Expanded(
                child: TranslatedCustomButton(
                  textKey: 'breeding.send_email',
                  icon: Icons.email,
                  type: ButtonType.secondary,
                  onPressed: () => _sendEmail(widget.pet.contactEmail),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Helper methods
  bool _hasHealthInfo() {
    return widget.pet.healthStatus.isNotEmpty || 
           widget.pet.temperament.isNotEmpty || 
           widget.pet.specialRequirements.isNotEmpty;
  }

  bool _hasRegistrationInfo() {
    return widget.pet.isRegistered || 
           widget.pet.registrationNumber.isNotEmpty || 
           widget.pet.certifications.isNotEmpty || 
           widget.pet.veterinarianContact.isNotEmpty;
  }

  bool _hasBreedingExperience() {
    return widget.pet.hasBreedingExperience || 
           widget.pet.breedingHistory.isNotEmpty || 
           widget.pet.previousOffspring.isNotEmpty;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Contact methods
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('breeding.cannot_make_call')),
        );
      }
    }
  }

  Future<void> _sendWhatsApp(String phoneNumber) async {
    final message = TranslationService.instance.translate('breeding.whatsapp_message').replaceAll('{0}', widget.pet.petName);
    final Uri url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('breeding.cannot_open_whatsapp')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final subject = TranslationService.instance.translate('breeding.email_subject').replaceAll('{0}', widget.pet.petName);
    final body = TranslationService.instance.translate('breeding.email_body').replaceAll('{0}', widget.pet.petName);
    final Uri url = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('breeding.cannot_open_email')),
        );
      }
    }
  }
} 