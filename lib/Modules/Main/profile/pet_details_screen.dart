import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';

class PetDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> pet;

  const PetDetailsScreen({
    super.key,
    required this.pet,
  });

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverFillRemaining(
              child: Column(
                children: [
                  _buildPetHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildMedicalTab(),
                        _buildVaccinationsTab(),
                        _buildHistoryTab(),
                      ],
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.h,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.pet['name'] ?? 'حيوان أليف',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.primaryGreen.withOpacity(0.8),
              ],
            ),
          ),
          child: widget.pet['imageUrl'] != null
              ? Image.network(
                  widget.pet['imageUrl'],
                  fit: BoxFit.cover,
                )
              : Icon(
                  Icons.pets,
                  size: 80.sp,
                  color: Colors.white.withOpacity(0.3),
                ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: _editPet,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'share':
                _sharePet();
                break;
              case 'delete':
                _deletePet();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('مشاركة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPetHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _getPetTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      widget.pet['type'] ?? 'غير محدد',
                      style: TextStyle(
                        color: _getPetTypeColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.pet['isNeutered'] == true)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 12.sp,
                            color: AppTheme.info,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'معقم',
                            style: TextStyle(
                              color: AppTheme.info,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              Row(
                children: [
                  _buildInfoItem(
                    icon: Icons.cake,
                    label: 'العمر',
                    value: '${widget.pet['age'] ?? 0} سنة',
                  ),
                  _buildInfoItem(
                    icon: Icons.monitor_weight,
                    label: 'الوزن',
                    value: '${widget.pet['weight'] ?? 0} كجم',
                  ),
                  _buildInfoItem(
                    icon: Icons.wc,
                    label: 'الجنس',
                    value: widget.pet['gender'] ?? 'غير محدد',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: AppTheme.primaryGreen,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
        tabs: const [
          Tab(text: 'نظرة عامة'),
          Tab(text: 'طبي'),
          Tab(text: 'تطعيمات'),
          Tab(text: 'التاريخ'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('المعلومات الأساسية'),
          SizedBox(height: 12.h),
          CustomCard(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildDetailRow('الاسم', widget.pet['name']),
                  _buildDetailRow('السلالة', widget.pet['breed']),
                  _buildDetailRow('اللون', widget.pet['color']),
                  if (widget.pet['microchip'] != null)
                    _buildDetailRow('الرقاقة الإلكترونية', widget.pet['microchip']),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24.h),
          
          _buildSectionTitle('جهة الاتصال الطارئ'),
          SizedBox(height: 12.h),
          CustomCard(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildDetailRow(
                    'الاسم', 
                    widget.pet['emergencyContact']?['name'],
                  ),
                  _buildDetailRow(
                    'الهاتف', 
                    widget.pet['emergencyContact']?['phone'],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalTab() {
    final allergies = widget.pet['allergies'] as List<dynamic>? ?? [];
    final medications = widget.pet['medications'] as List<dynamic>? ?? [];
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allergies.isNotEmpty) ...[
            _buildSectionTitle('الحساسيات'),
            SizedBox(height: 12.h),
            CustomCard(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: allergies.map((allergy) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppTheme.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        allergy.toString(),
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
          
          if (medications.isNotEmpty) ...[
            _buildSectionTitle('الأدوية الحالية'),
            SizedBox(height: 12.h),
            CustomCard(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: medications.map((medication) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medication,
                            size: 16.sp,
                            color: AppTheme.info,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              medication.toString(),
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
          
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'إضافة حساسية',
                  onPressed: () => _addAllergy(),
                  backgroundColor: AppTheme.warning,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomButton(
                  text: 'إضافة دواء',
                  onPressed: () => _addMedication(),
                  backgroundColor: AppTheme.info,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationsTab() {
    final vaccinations = widget.pet['vaccinations'] as List<dynamic>? ?? [];
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomButton(
            text: 'إضافة تطعيم جديد',
            onPressed: () => _addVaccination(),
            backgroundColor: AppTheme.primaryGreen,
            textColor: Colors.white,
            icon: Icons.add,
          ),
          
          SizedBox(height: 20.h),
          
          if (vaccinations.isNotEmpty) ...[
            _buildSectionTitle('التطعيمات'),
            SizedBox(height: 12.h),
            ...vaccinations.map((vaccination) {
              return _buildVaccinationCard(vaccination);
            }).toList(),
          ] else
            _buildEmptyVaccinationsState(),
        ],
      ),
    );
  }

  Widget _buildVaccinationCard(Map<String, dynamic> vaccination) {
    final nextDue = DateTime.tryParse(vaccination['nextDue'] ?? '');
    final isOverdue = nextDue != null && nextDue.isBefore(DateTime.now());
    final isDueSoon = nextDue != null && 
        nextDue.isBefore(DateTime.now().add(const Duration(days: 30))) &&
        nextDue.isAfter(DateTime.now());
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vaccination['name'] ?? 'تطعيم غير محدد',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'متأخر',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (isDueSoon)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'قريباً',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'آخر تطعيم: ${vaccination['date'] ?? 'غير محدد'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 4.h),
              
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'التطعيم القادم: ${vaccination['nextDue'] ?? 'غير محدد'}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isOverdue 
                          ? AppTheme.error 
                          : isDueSoon 
                              ? AppTheme.warning 
                              : Colors.grey[600],
                      fontWeight: isOverdue || isDueSoon 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final medicalHistory = widget.pet['medicalHistory'] as List<dynamic>? ?? [];
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomButton(
            text: 'إضافة سجل طبي',
            onPressed: () => _addMedicalRecord(),
            backgroundColor: AppTheme.primaryGreen,
            textColor: Colors.white,
            icon: Icons.add,
          ),
          
          SizedBox(height: 20.h),
          
          if (medicalHistory.isNotEmpty) ...[
            _buildSectionTitle('التاريخ الطبي'),
            SizedBox(height: 12.h),
            ...medicalHistory.map((record) {
              return _buildMedicalRecordCard(record);
            }).toList(),
          ] else
            _buildEmptyHistoryState(),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordCard(Map<String, dynamic> record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getRecordTypeColor(record['type']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      record['type'] ?? 'عام',
                      style: TextStyle(
                        color: _getRecordTypeColor(record['type']),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    record['date'] ?? '',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              Text(
                record['description'] ?? 'لا يوجد وصف',
                style: TextStyle(fontSize: 14.sp),
              ),
              
              if (record['vetName'] != null) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      record['vetName'],
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'غير محدد',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVaccinationsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد تطعيمات مسجلة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'أضف تطعيمات حيوانك الأليف لمتابعة جدولها',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'لا يوجد تاريخ طبي',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'أضف السجلات الطبية لحيوانك الأليف',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPetTypeColor() {
    switch (widget.pet['type']?.toLowerCase()) {
      case 'كلب':
      case 'dog':
        return Colors.brown;
      case 'قطة':
      case 'cat':
        return Colors.orange;
      case 'أرنب':
      case 'rabbit':
        return Colors.pink;
      case 'طائر':
      case 'bird':
        return Colors.blue;
      default:
        return AppTheme.primaryGreen;
    }
  }

  Color _getRecordTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'تطعيم':
      case 'vaccination':
        return AppTheme.success;
      case 'فحص':
      case 'checkup':
        return AppTheme.info;
      case 'علاج':
      case 'treatment':
        return AppTheme.warning;
      case 'جراحة':
      case 'surgery':
        return AppTheme.error;
      default:
        return AppTheme.primaryGreen;
    }
  }

  void _editPet() {
    // TODO: Navigate to edit pet screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة التعديل ستكون متاحة قريباً')),
    );
  }

  void _sharePet() {
    // TODO: Implement pet sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة المشاركة ستكون متاحة قريباً')),
    );
  }

  void _deletePet() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحيوان الأليف'),
        content: Text('هل أنت متأكد من حذف ${widget.pet['name']}؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف ${widget.pet['name']}'),
                  backgroundColor: AppTheme.error,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _addAllergy() {
    // TODO: Implement add allergy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة إضافة الحساسيات ستكون متاحة قريباً')),
    );
  }

  void _addMedication() {
    // TODO: Implement add medication
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة إضافة الأدوية ستكون متاحة قريباً')),
    );
  }

  void _addVaccination() {
    // TODO: Implement add vaccination
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة إضافة التطعيمات ستكون متاحة قريباً')),
    );
  }

  void _addMedicalRecord() {
    // TODO: Implement add medical record
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة إضافة السجل الطبي ستكون متاحة قريباً')),
    );
  }
} 