import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/translation_service.dart';
import '../../../Models/pet_report_model.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../Utilities/dialog_helper.dart';
import '../../../Widgets/login_widget.dart';
import 'user_chat_screen.dart';

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
        // البحث عن description في report مباشرة أو في petDetails
        final report = widget.report!;
        return report['description']?.toString() ?? 
               (report['petDetails'] as Map<String, dynamic>?)?['description']?.toString() ?? '';
      case PetDetailsType.adoption:
        return widget.adoptionPet!.description;
      case PetDetailsType.breeding:
        return widget.breedingPet!.description;
    }
  }

  // دالة لترجمة نوع الحيوان
  String _translatePetType(String petType) {
    final translationService = TranslationService.instance;
    String key = petType.toLowerCase().replaceAll(' ', '_');
    
    // محاولة الترجمة من animal_types
    try {
      String translated = translationService.translate('add_animal.pet_details.animal_types.$key');
      // إذا كانت الترجمة مختلفة عن المفتاح، فهي ترجمة صحيحة
      if (translated != 'add_animal.pet_details.animal_types.$key') {
        return translated;
      }
    } catch (e) {
      // إذا فشلت الترجمة، استخدم القيمة الأصلية
    }
    
    // إذا لم تكن هناك ترجمة، استخدم القيمة الأصلية
    return petType;
  }

  // دالة لترجمة الجنس
  String _translateGender(String gender) {
    final translationService = TranslationService.instance;
    
    // تحويل القيمة إلى مفتاح الترجمة
    String genderKey = gender.toLowerCase();
    if (genderKey == 'male') {
      return translationService.translate('add_animal.pet_details.male');
    } else if (genderKey == 'female') {
      return translationService.translate('add_animal.pet_details.female');
    } else if (genderKey == 'unknown') {
      return translationService.translate('add_animal.pet_details.unknown');
    }
    
    // إذا كانت القيمة بالفعل مترجمة أو غير معروفة، استخدمها كما هي
    return gender;
  }

  // معرض صور محسّن يعرض جميع الصور - تصميم جديد يشبه الصورة
  Widget _buildEnhancedImageGallery() {
    if (_images.isEmpty) return const SizedBox.shrink();

    // إذا كانت هناك صورة واحدة فقط، عرضها كاملة
    if (_images.length == 1) {
      return Container(
        height: 280.h,
        margin: EdgeInsets.only(bottom: 16.h),
        child: GestureDetector(
          onTap: () => _showFullScreenImage(0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: CachedNetworkImage(
                imageUrl: _images[0],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                memCacheWidth: 800,
                memCacheHeight: 600,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey[600],
                    size: 40.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 280.h,
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصورة الرئيسية الكبيرة على اليسار
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _showFullScreenImage(0),
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: CachedNetworkImage(
                    imageUrl: _images[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    memCacheWidth: 800,
                    memCacheHeight: 600,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey[600],
                        size: 40.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // صورتان صغيرتان على اليمين
          Expanded(
            flex: 1,
            child: Column(
              children: [
                if (_images.length > 1)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(1),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: CachedNetworkImage(
                            imageUrl: _images[1],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            memCacheWidth: 400,
                            memCacheHeight: 300,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryGreen,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey[600],
                                size: 30.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_images.length > 1) SizedBox(height: 8.h),
                if (_images.length > 2)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(2),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: CachedNetworkImage(
                            imageUrl: _images[2],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            memCacheWidth: 400,
                            memCacheHeight: 300,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryGreen,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey[600],
                                size: 30.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_images.length == 2)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معرض الصور المحسّن
              if (_images.isNotEmpty) ...[
                _buildEnhancedImageGallery(),
                // مؤشرات الصور (النقاط البيضاء)
                if (_images.length > 1)
                  Padding(
                    padding: EdgeInsets.only(top: 12.h, bottom: 24.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _images.length > 4 ? 4 : _images.length,
                        (index) => Container(
                          width: 8.w,
                          height: 8.h,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 0 
                                ? Colors.grey[600] 
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(height: 24.h),
              ] else
                SizedBox(height: 16.h),
              // اسم الحيوان والسلالة - في المنتصف
              _buildPetNameAndBreed(),
              SizedBox(height: 24.h),
              // ثلاث بطاقات المعلومات (Color, Gender, Type)
              _buildInfoCardsRow(),
              SizedBox(height: 24.h),
              // قسم الوصف
              if (_description.isNotEmpty) ...[
                _buildDescriptionSection(),
                SizedBox(height: 24.h),
              ],
              // زر "Contact Us" - يظهر فقط إذا لم يكن المستخدم هو صاحب الإعلان
              if (!_isCurrentUserOwner()) ...[
                _buildContactUsButton(),
                SizedBox(height: 32.h),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // اسم الحيوان والسلالة - في المنتصف
  Widget _buildPetNameAndBreed() {
    String breed = '';
    switch (widget.type) {
      case PetDetailsType.report:
        final petDetails = widget.report!['petDetails'] as Map<String, dynamic>? ?? {};
        breed = petDetails['breed']?.toString() ?? '';
        break;
      case PetDetailsType.adoption:
        breed = widget.adoptionPet!.breed;
        break;
      case PetDetailsType.breeding:
        breed = widget.breedingPet!.breed;
        break;
    }

    return Column(
      children: [
        Text(
          _petName,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        if (breed.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            breed,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ثلاث بطاقات المعلومات (Color, Gender, Type)
  Widget _buildInfoCardsRow() {
    String color = '';
    String gender = '';
    String type = '';

    switch (widget.type) {
      case PetDetailsType.report:
        final report = widget.report!;
        final petDetails = report['petDetails'] as Map<String, dynamic>? ?? {};
        color = report['color']?.toString() ?? petDetails['color']?.toString() ?? '';
        gender = report['gender']?.toString() ?? petDetails['gender']?.toString() ?? '';
        type = report['petType']?.toString() ?? petDetails['type']?.toString() ?? petDetails['petType']?.toString() ?? '';
        if (type.isNotEmpty) {
          type = _translatePetType(type);
        }
        break;
      case PetDetailsType.adoption:
        final pet = widget.adoptionPet!;
        color = pet.color;
        gender = pet.gender;
        type = pet.petType;
        break;
      case PetDetailsType.breeding:
        final pet = widget.breedingPet!;
        color = pet.color;
        gender = pet.gender;
        type = pet.petType;
        break;
    }

    if (gender.isNotEmpty) {
      gender = _translateGender(gender);
    }

    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.palette,
            iconColor: const Color(0xFF8B4513), // Brown color
            label: TranslationService.instance.translate('add_animal.pet_details.color'),
            value: color.isNotEmpty ? color : '-',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.wc,
            iconColor: Colors.pink,
            label: TranslationService.instance.translate('add_animal.pet_details.gender'),
            value: gender.isNotEmpty ? gender : '-',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.pets,
            iconColor: const Color(0xFF87CEEB), // Light blue
            label: TranslationService.instance.translate('add_animal.pet_details.pet_type'),
            value: type.isNotEmpty ? type : '-',
          ),
        ),
      ],
    );
  }

  // بطاقة معلومات واحدة (للبطاقات الثلاث: Color, Gender, Type)
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.instance.translate('add_animal.pet_details.description'),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _description,
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String? _getOwnerUserId() {
    switch (widget.type) {
      case PetDetailsType.report:
        return widget.report!['userId'] as String?;
      case PetDetailsType.adoption:
        return widget.adoptionPet!.userId;
      case PetDetailsType.breeding:
        return widget.breedingPet!.userId;
    }
  }

  bool _isCurrentUserOwner() {
    if (!AuthService.isAuthenticated) return false;
    final currentUserId = AuthService.userId;
    final ownerUserId = _getOwnerUserId();
    return currentUserId != null && ownerUserId != null && currentUserId == ownerUserId;
  }

  String? _getPetReportId() {
    switch (widget.type) {
      case PetDetailsType.report:
        return widget.report!['id'] as String?;
      case PetDetailsType.adoption:
        return widget.adoptionPet?.id;
      case PetDetailsType.breeding:
        return widget.breedingPet?.id;
    }
  }

  String? _getPetReportType() {
    switch (widget.type) {
      case PetDetailsType.report:
        return widget.report!['type'] as String?; // 'lost' or 'found'
      case PetDetailsType.adoption:
        return 'adoption';
      case PetDetailsType.breeding:
        return 'breeding';
    }
  }

  Future<void> _startChatWithOwner() async {
    if (!AuthService.isAuthenticated) {
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: const LoginWidget(),
      );
      return;
    }

    final ownerUserId = _getOwnerUserId();
    if (ownerUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.instance.translate('add_animal.messages.owner_not_found'))),
      );
      return;
    }

    final currentUserId = AuthService.userId!;
    if (currentUserId == ownerUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.instance.translate('add_animal.messages.cannot_chat_with_self'))),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryGreen),
                SizedBox(height: 16.h),
                Text(TranslationService.instance.translate('add_animal.messages.opening_chat')),
              ],
            ),
          ),
        ),
      );

      // Get owner name for initial message
      String ownerName = 'صاحب الإعلان';
      try {
        final ownerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUserId)
            .get();
        if (ownerDoc.exists) {
          ownerName = ownerDoc.data()?['name'] ?? 
                     ownerDoc.data()?['username'] ?? 
                     'صاحب الإعلان';
        }
      } catch (e) {
        // Could not fetch owner name
      }

      final petReportId = _getPetReportId();
      final petReportType = _getPetReportType();

      final initialMessage = TranslationService.instance.translate('add_animal.messages.chat_initial_message')
          .replaceAll('{0}', _petName);
      
      final chatId = await ChatService.createChatWithUser(
        userId: currentUserId,
        otherUserId: ownerUserId,
        initialMessage: initialMessage,
        petReportId: petReportId,
        petReportType: petReportType,
      );

      Navigator.pop(context); // Close loading dialog

      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserChatScreen(
            chatId: chatId,
            otherUserId: ownerUserId,
            otherUserName: ownerName,
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.instance.translate('add_animal.messages.chat_error').replaceAll('{0}', e.toString())),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // زر "Contact Us" باللون الأخضر
  Widget _buildContactUsButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _startChatWithOwner,
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child: Text(
              TranslationService.instance.translate('contact_us'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
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
                        color: Colors.black.withValues(alpha: 0.6),
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
                        color: Colors.black.withValues(alpha: 0.6),
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

