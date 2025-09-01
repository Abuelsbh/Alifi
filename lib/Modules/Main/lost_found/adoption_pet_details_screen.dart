import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/translated_text.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/translated_custom_button.dart';
import '../../../core/Language/translation_service.dart';

class AdoptionPetDetailsScreen extends StatefulWidget {
  final AdoptionPetModel pet;

  const AdoptionPetDetailsScreen({
    super.key,
    required this.pet,
  });

  @override
  State<AdoptionPetDetailsScreen> createState() => _AdoptionPetDetailsScreenState();
}

class _AdoptionPetDetailsScreenState extends State<AdoptionPetDetailsScreen> {
  int _currentImageIndex = 0;
  PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('=== AdoptionPetDetailsScreen Debug ===');
    print('Pet Name: ${widget.pet.petName}');
    print('Pet Type: ${widget.pet.petType}');
    print('Pet Age: ${widget.pet.age}');
    print('Pet Photos Count: ${widget.pet.photos.length}');
    print('Pet Photos List: ${widget.pet.photos}');
    for (int i = 0; i < widget.pet.photos.length; i++) {
      print('Photo $i: ${widget.pet.photos[i]}');
    }
    print('Pet Description: ${widget.pet.description}');
    print('Pet Address: ${widget.pet.address}');
    print('Pet Adoption Fee: ${widget.pet.adoptionFee}');
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
                    'adoption.pet_details',
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
                            print('🖼️ Loading image ${index + 1}/${widget.pet.photos.length}: ${widget.pet.photos[index]}');
                            return Image.network(
                              widget.pet.photos[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  print('✅ Image ${index + 1} loaded successfully');
                                  return child;
                                }
                                print('⏳ Loading image ${index + 1}... ${(loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) * 100).toStringAsFixed(1)}%');
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
                                print('❌ Error loading image ${index + 1}: $error');
                                print('Image URL: ${widget.pet.photos[index]}');
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
                                      SizedBox(height: 4.h),
                                      Text(
                                        'الصورة ${index + 1} من ${widget.pet.photos.length}',
                                        style: TextStyle(
                                          color: AppTheme.primaryGreen.withOpacity(0.7),
                                          fontSize: 12.sp,
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
                          SizedBox(height: 4.h),
                          Text(
                            'تم العثور على ${widget.pet.photos.length} صورة',
                            style: TextStyle(
                              color: AppTheme.primaryGreen.withOpacity(0.7),
                              fontSize: 12.sp,
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
                  
                  // Health & Care Info (only if has health info)
                  if (_hasHealthInfo()) ...[
                    SizedBox(height: 24.h),
                    _buildHealthCareSection(),
                  ],
                  
                  // Personality & Behavior (only if has personality info)
                  if (_hasPersonalityInfo()) ...[
                    SizedBox(height: 24.h),
                    _buildPersonalitySection(),
                  ],
                  
                  // Medical History (only if not empty)
                  if (widget.pet.medicalHistory.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _buildMedicalHistorySection(),
                  ],
                  
                  // Adoption Requirements (only if reason is not empty)
                  if (widget.pet.reason.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _buildAdoptionRequirementsSection(),
                  ],
                  
                  SizedBox(height: 24.h),
                  
                  // Contact Info
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
    print('Building basic info section...');
    print('Pet Name: "${widget.pet.petName}"');
    print('Pet Type: "${widget.pet.petType}"');
    print('Pet Age: ${widget.pet.age}');
    print('Pet Gender: "${widget.pet.gender}"');
    print('Pet Breed: "${widget.pet.breed}"');
    print('Pet Color: "${widget.pet.color}"');
    print('Pet Weight: ${widget.pet.weight}');
    print('Adoption Fee: ${widget.pet.adoptionFee}');
    
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
                if (widget.pet.adoptionFee > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${widget.pet.adoptionFee.toStringAsFixed(0)} ج.م',
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
                      'adoption.free',
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
                  _buildInfoItem(Icons.cake, '${widget.pet.age} ${TranslationService.instance.translate('adoption.years')}'),
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
              _buildInfoItem(Icons.monitor_weight, '${widget.pet.weight} ${TranslationService.instance.translate('adoption.kg')}'),
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
      features.add(_buildFeatureChip('adoption.vaccinated', Icons.medical_services, Colors.green));
    }
    if (widget.pet.isNeutered) {
      features.add(_buildFeatureChip('adoption.neutered', Icons.medical_services, Colors.blue));
    }
    if (widget.pet.goodWithKids) {
      features.add(_buildFeatureChip('adoption.good_with_kids', Icons.child_care, Colors.orange));
    }
    if (widget.pet.goodWithPets) {
      features.add(_buildFeatureChip('adoption.good_with_pets', Icons.pets, Colors.purple));
    }
    if (widget.pet.isHouseTrained) {
      features.add(_buildFeatureChip('adoption.house_trained', Icons.home, Colors.teal));
    }

    if (features.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'adoption.features',
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
    if (widget.pet.description.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'adoption.description',
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

  Widget _buildHealthCareSection() {
    // Only show if we have some health information
    bool hasHealthInfo = widget.pet.healthStatus.isNotEmpty || 
                        widget.pet.microchipId.isNotEmpty || 
                        widget.pet.specialNeeds.isNotEmpty;
    
    if (!hasHealthInfo) {
      return const SizedBox.shrink();
    }
    
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'adoption.health_care',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 16.h),
            if (widget.pet.healthStatus.isNotEmpty)
              _buildHealthItem('adoption.health_status', widget.pet.healthStatus, Icons.favorite),
            if (widget.pet.microchipId.isNotEmpty) ...[
              if (widget.pet.healthStatus.isNotEmpty) SizedBox(height: 12.h),
              _buildHealthItem('adoption.microchip_id', widget.pet.microchipId, Icons.memory),
            ],
            if (widget.pet.specialNeeds.isNotEmpty) ...[
              if (widget.pet.healthStatus.isNotEmpty || widget.pet.microchipId.isNotEmpty) SizedBox(height: 12.h),
              _buildHealthItem('adoption.special_needs', widget.pet.specialNeeds, Icons.medical_information),
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

  Widget _buildPersonalitySection() {
    // Only show if we have personality information
    bool hasPersonalityInfo = widget.pet.temperament.isNotEmpty || 
                             widget.pet.preferredHomeType.isNotEmpty;
    
    if (!hasPersonalityInfo) {
      return const SizedBox.shrink();
    }
    
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'adoption.personality_behavior',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 16.h),
            if (widget.pet.temperament.isNotEmpty)
              _buildPersonalityItem('adoption.temperament', widget.pet.temperament, Icons.mood),
            if (widget.pet.preferredHomeType.isNotEmpty) ...[
              if (widget.pet.temperament.isNotEmpty) SizedBox(height: 12.h),
              _buildPersonalityItem('adoption.preferred_home_type', widget.pet.preferredHomeType, Icons.home_work),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityItem(String labelKey, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: AppTheme.primaryGreen,
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              labelKey,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicalHistorySection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'adoption.medical_history',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 12.h),
            ...widget.pet.medicalHistory.map((history) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 6.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      history,
                      style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildAdoptionRequirementsSection() {
    if (widget.pet.reason.isEmpty) return const SizedBox.shrink();
    
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(
              'adoption.reason_for_adoption',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              widget.pet.reason,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
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
              'adoption.contact_information',
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
                  '${TranslationService.instance.translate('adoption.posted_on').replaceAll('{0}', _formatDate(widget.pet.createdAt))}',
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
            textKey: 'adoption.contact_owner',
            icon: Icons.phone,
            onPressed: () => _makePhoneCall(widget.pet.contactPhone),
            backgroundColor: AppTheme.primaryGreen,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: TranslatedCustomButton(
                textKey: 'adoption.send_whatsapp',
                icon: Icons.message,
                type: ButtonType.secondary,
                onPressed: () => _sendWhatsApp(widget.pet.contactPhone),
              ),
            ),
            if (widget.pet.contactEmail.isNotEmpty) ...[
              SizedBox(width: 12.w),
              Expanded(
                child: TranslatedCustomButton(
                  textKey: 'adoption.send_email',
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('adoption.cannot_make_call')),
        );
      }
    }
  }

  Future<void> _sendWhatsApp(String phoneNumber) async {
    final message = TranslationService.instance.translate('adoption.whatsapp_message').replaceAll('{0}', widget.pet.petName);
    final Uri url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('adoption.cannot_open_whatsapp')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final subject = TranslationService.instance.translate('adoption.email_subject').replaceAll('{0}', widget.pet.petName);
    final body = TranslationService.instance.translate('adoption.email_body').replaceAll('{0}', widget.pet.petName);
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
          SnackBar(content: TranslatedText('adoption.cannot_open_email')),
        );
      }
    }
  }

  bool _hasHealthInfo() {
    return widget.pet.healthStatus.isNotEmpty || 
           widget.pet.microchipId.isNotEmpty || 
           widget.pet.specialNeeds.isNotEmpty;
  }

  bool _hasPersonalityInfo() {
    return widget.pet.temperament.isNotEmpty || 
           widget.pet.preferredHomeType.isNotEmpty;
  }
} 