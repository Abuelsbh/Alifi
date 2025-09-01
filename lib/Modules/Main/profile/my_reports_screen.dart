import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Models/pet_report_model.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';
import '../../../Widgets/translated_text.dart';
import '../lost_found/pet_report_details_screen.dart';
import '../lost_found/post_report_screen.dart';
import '../lost_found/lost_found_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _myReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, lost, found, active, resolved

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyReports() async {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = AuthService.userId!;
      
      // استمع للتحديثات المباشرة
      PetReportsService.getUserReportsStream(userId).listen((reports) {
        if (mounted) {
          setState(() {
            _myReports = reports;
            _filterReports();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل التقارير: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _filterReports() {
    List<Map<String, dynamic>> filtered = List.from(_myReports);

    switch (_selectedFilter) {
      case 'lost':
        filtered = filtered.where((report) => report['type'] == 'lost').toList();
        break;
      case 'found':
        filtered = filtered.where((report) => report['type'] == 'found').toList();
        break;
      case 'active':
        filtered = filtered.where((report) => report['isActive'] == true && report['isResolved'] != true).toList();
        break;
      case 'resolved':
        filtered = filtered.where((report) => report['isResolved'] == true).toList();
        break;
      default:
        // عرض الكل
        break;
    }

    setState(() {
      _filteredReports = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'تقاريري',
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  PostReportScreen(
                    reportType: ReportType.lost,
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.add,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter buttons
          _buildFilterButtons(),
          
          // Reports count
          _buildReportsCount(),
          
          // Reports list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                    ? _buildEmptyState()
                    : _buildReportsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'الكل'),
            SizedBox(width: 8.w),
            _buildFilterChip('lost', 'مفقود'),
            SizedBox(width: 8.w),
            _buildFilterChip('found', 'موجود'),
            SizedBox(width: 8.w),
            _buildFilterChip('active', 'نشط'),
            SizedBox(width: 8.w),
            _buildFilterChip('resolved', 'محلول'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
          _filterReports();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildReportsCount() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16.sp, color: AppTheme.primaryGreen),
          SizedBox(width: 8.w),
          Text(
            'إجمالي التقارير: ${_filteredReports.length}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
        ],
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
            size: 64.sp,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد تقارير',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'لم تقم بإضافة أي تقارير حيوانات بعد',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: 'إضافة تقرير جديد',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PostReportScreen(
                    reportType: ReportType.lost,
                  ),
                ),
              );
            },
            type: ButtonType.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredReports.length,
      itemBuilder: (context, index) {
        final report = _filteredReports[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildReportCard(report),
        );
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final isLostPet = report['type'] == 'lost';
    final petName = isLostPet 
        ? (report['petDetails']?['name'] ?? report['petName'] ?? 'حيوان مفقود')
        : 'حيوان موجود';
    final petType = report['petDetails']?['type'] ?? report['petType'] ?? 'غير محدد';
    final location = report['location']?['address'] ?? 
                    report['lastSeenLocation'] ?? 
                    report['foundLocation'] ?? 
                    report['address'] ?? '';
    final imageUrls = report['imageUrls'] as List<dynamic>? ?? [];
    final isActive = report['isActive'] ?? true;
    final isResolved = report['isResolved'] ?? false;
    final isUrgent = report['isUrgent'] ?? false;

    return CustomCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetReportDetailsScreen(report: report),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // صورة الحيوان
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.grey[300],
                  ),
                  child: imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            imageUrls.first.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                Icon(Icons.pets, size: 40.sp, color: AppTheme.primaryGreen),
                          ),
                        )
                      : Icon(Icons.pets, size: 40.sp, color: AppTheme.primaryGreen),
                ),
                
                SizedBox(width: 16.w),
                
                // معلومات الحيوان
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              petName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status badges
                          if (isUrgent) ...[
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'عاجل',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: isLostPet 
                                  ? AppTheme.warning.withOpacity(0.1)
                                  : AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              isLostPet ? 'مفقود' : 'موجود',
                              style: TextStyle(
                                color: isLostPet ? AppTheme.warning : AppTheme.success,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 4.h),
                      Text(
                        petType,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14.sp, color: AppTheme.primaryGreen),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              location.isNotEmpty ? location : 'غير محدد',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Status and actions
            Row(
              children: [
                // Status indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isResolved 
                        ? AppTheme.success.withOpacity(0.1)
                        : isActive 
                            ? AppTheme.primaryGreen.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    isResolved ? 'تم الحل' : isActive ? 'نشط' : 'غير نشط',
                    style: TextStyle(
                      color: isResolved 
                          ? AppTheme.success
                          : isActive 
                              ? AppTheme.primaryGreen
                              : Colors.grey,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Actions
                if (isActive && !isResolved) ...[
                  TextButton(
                    onPressed: () {
                      _markAsResolved(report);
                    },
                    child: Text(
                      'تم العثور عليه',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
                
                IconButton(
                  onPressed: () {
                    _showOptionsMenu(report);
                  },
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    size: 20.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _markAsResolved(Map<String, dynamic> report) async {
    try {
      final collection = report['type'] == 'lost' ? 'lost_pets' : 'found_pets';
      await PetReportsService.markReportAsResolved(
        reportId: report['id'],
        collection: collection,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة التقرير بنجاح'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث الحالة: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showOptionsMenu(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit, color: AppTheme.primaryGreen),
                    title: Text('تعديل التقرير'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to edit report screen
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.share, color: AppTheme.primaryGreen),
                    title: Text('مشاركة التقرير'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement share functionality
                    },
                  ),
                  if (report['isActive'] == true) ...[
                    ListTile(
                      leading: Icon(Icons.check_circle, color: AppTheme.success),
                      title: Text('تم العثور عليه'),
                      onTap: () {
                        Navigator.pop(context);
                        _markAsResolved(report);
                      },
                    ),
                  ],
                  ListTile(
                    leading: Icon(Icons.delete, color: AppTheme.error),
                    title: Text('حذف التقرير'),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteReport(report);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteReport(Map<String, dynamic> report) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف التقرير'),
        content: Text('هل أنت متأكد من رغبتك في حذف هذا التقرير؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final collection = report['type'] == 'lost' ? 'lost_pets' : 'found_pets';
        await PetReportsService.deleteReport(
          reportId: report['id'],
          collection: collection,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف التقرير بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف التقرير: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
} 