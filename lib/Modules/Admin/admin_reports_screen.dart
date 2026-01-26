import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../Utilities/text_style_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedFilter = 'all';
  final List<String> _filterOptions = ['all', 'pending', 'approved', 'rejected'];
  String _activeFilter = 'all'; // 'all', 'active', 'inactive'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('غير مصرح'),
        ),
        body: const Center(
          child: Text('ليس لديك صلاحية للوصول إلى هذه الصفحة'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة التقارير'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'حذف جميع التقارير',
            onPressed: () => _deleteAllReports(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن تقرير...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 12.h),
                // Filter Chips - Approval Status
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: FilterChip(
                          label: Text(_getFilterLabel(filter)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          selectedColor: AppTheme.primaryGreen,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 12.h),
                // Active/Inactive Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: FilterChip(
                          label: const Text('الكل'),
                          selected: _activeFilter == 'all',
                          onSelected: (selected) {
                            setState(() {
                              _activeFilter = 'all';
                            });
                          },
                          selectedColor: AppTheme.primaryGreen,
                          labelStyle: TextStyle(
                            color: _activeFilter == 'all' ? Colors.white : Colors.black87,
                            fontWeight: _activeFilter == 'all' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: FilterChip(
                          label: const Text('نشط'),
                          selected: _activeFilter == 'active',
                          onSelected: (selected) {
                            setState(() {
                              _activeFilter = 'active';
                            });
                          },
                          selectedColor: Colors.green,
                          labelStyle: TextStyle(
                            color: _activeFilter == 'active' ? Colors.white : Colors.black87,
                            fontWeight: _activeFilter == 'active' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: FilterChip(
                          label: const Text('غير نشط'),
                          selected: _activeFilter == 'inactive',
                          onSelected: (selected) {
                            setState(() {
                              _activeFilter = 'inactive';
                            });
                          },
                          selectedColor: Colors.grey,
                          labelStyle: TextStyle(
                            color: _activeFilter == 'inactive' ? Colors.white : Colors.black87,
                            fontWeight: _activeFilter == 'inactive' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Reports List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: PetReportsService.getAllReportsForAdmin(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('خطأ: ${snapshot.error}'),
                  );
                }

                final allReports = snapshot.data ?? [];
                final filteredReports = _filterReports(allReports);

                if (filteredReports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets,
                          size: 64.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'لا توجد تقارير',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return _buildReportCard(report);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'الكل';
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'موافق عليها';
      case 'rejected':
        return 'مرفوضة';
      default:
        return filter;
    }
  }

  List<Map<String, dynamic>> _filterReports(List<Map<String, dynamic>> reports) {
    var filtered = reports;

    // Filter by active/inactive status
    if (_activeFilter != 'all') {
      filtered = filtered.where((report) {
        final isActive = report['isActive'] ?? true;
        if (_activeFilter == 'active') {
          return isActive == true;
        } else if (_activeFilter == 'inactive') {
          return isActive != true;
        }
        return true;
      }).toList();
    }

    // Filter by approval status
    if (_selectedFilter != 'all') {
      filtered = filtered.where((report) {
        final approvalStatus = report['approvalStatus'] ?? 'pending';
        return approvalStatus == _selectedFilter;
      }).toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((report) {
        final petDetails = report['petDetails'] as Map<String, dynamic>? ?? {};
        final petName = (petDetails['name'] ?? '').toString().toLowerCase();
        final petType = (petDetails['type'] ?? '').toString().toLowerCase();
        final description = (report['description'] ?? '').toString().toLowerCase();
        
        return petName.contains(query) ||
            petType.contains(query) ||
            description.contains(query);
      }).toList();
    }

    return filtered;
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final petDetails = report['petDetails'] as Map<String, dynamic>? ?? {};
    final petName = petDetails['name'] ?? 'Unnamed Pet';
    final petType = petDetails['type'] ?? 'Unknown';
    final imageUrls = report['imageUrls'] as List<dynamic>? ?? [];
    final approvalStatus = report['approvalStatus'] ?? 'pending';
    final createdAt = (report['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final reportType = report['type'] ?? report['collection']?.toString().replaceAll('_pets', '') ?? 'unknown';

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Pet Image - Fixed Size
                if (imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CachedNetworkImage(
                      imageUrl: imageUrls[0],
                      width: 100.w,
                      height: 100.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 100.w,
                        height: 100.h,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 100.w,
                        height: 100.h,
                        color: Colors.grey[200],
                        child: const Icon(Icons.pets),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 100.w,
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const Icon(Icons.pets, size: 40),
                  ),
                SizedBox(width: 12.w),
                // Pet Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petName,
                        style: TextStyleHelper.of(context).s18RegTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        petType,
                        style: TextStyleHelper.of(context).s14RegTextStyle.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyleHelper.of(context).s12RegTextStyle.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badges Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Approval Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(approvalStatus),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        _getStatusLabel(approvalStatus),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // Active/Inactive Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: (report['isActive'] ?? true) ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        (report['isActive'] ?? true) ? 'نشط' : 'غير نشط',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Type Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _getTypeColor(reportType),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _getTypeLabel(reportType),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (approvalStatus != 'approved')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveReport(report),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('موافقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                if (approvalStatus != 'approved') SizedBox(width: 8.w),
                if (approvalStatus != 'rejected')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectReport(report),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('رفض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                if (approvalStatus != 'rejected') SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteReport(report),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('حذف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _permanentlyDeleteReport(report),
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('حذف نهائي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'موافق';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
      default:
        return 'قيد الانتظار';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'lost':
        return Colors.blue;
      case 'found':
        return Colors.green;
      case 'adoption':
        return Colors.purple;
      case 'breeding':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'lost':
        return 'مفقود';
      case 'found':
        return 'موجود';
      case 'adoption':
        return 'للتبني';
      case 'breeding':
        return 'للتزاوج';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _approveReport(Map<String, dynamic> report) async {
    try {
      final reportId = report['id']?.toString();
      final collection = report['collection']?.toString();
      
      print('🔍 Approving report:');
      print('   reportId: $reportId');
      print('   collection: $collection');
      print('   Full report: $report');
      
      if (reportId == null || collection == null) {
        throw Exception('Missing report ID or collection');
      }
      
      await PetReportsService.approveReport(
        reportId: reportId,
        collection: collection,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الموافقة على التقرير بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الموافقة: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectReport(Map<String, dynamic> report) async {
    try {
      final reportId = report['id']?.toString();
      final collection = report['collection']?.toString();
      
      print('🔍 Rejecting report:');
      print('   reportId: $reportId');
      print('   collection: $collection');
      print('   Full report: $report');
      
      if (reportId == null || collection == null) {
        throw Exception('Missing report ID or collection');
      }
      
      await PetReportsService.rejectReport(
        reportId: reportId,
        collection: collection,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض التقرير بنجاح'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الرفض: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteReport(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا التقرير؟\nسيتم إخفاؤه من القائمة ولكن سيظل موجوداً في قاعدة البيانات.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final reportId = report['id']?.toString();
        final collection = report['collection']?.toString();
        
        print('🔍 Deleting report:');
        print('   reportId: $reportId');
        print('   collection: $collection');
        
        if (reportId == null || collection == null) {
          throw Exception('Missing report ID or collection');
        }
        
        await PetReportsService.deleteReport(
          reportId: reportId,
          collection: collection,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف التقرير بنجاح'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الحذف: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _permanentlyDeleteReport(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف النهائي'),
        content: const Text('هل أنت متأكد من حذف هذا التقرير نهائياً من قاعدة البيانات؟\n\nهذا الإجراء لا يمكن التراجع عنه وسيتم حذف التقرير والصور المرتبطة به نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف نهائي', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final reportId = report['id']?.toString();
        final collection = report['collection']?.toString();
        
        print('🗑️ Permanently deleting report:');
        print('   reportId: $reportId');
        print('   collection: $collection');
        
        if (reportId == null || collection == null) {
          throw Exception('Missing report ID or collection');
        }
        
        await PetReportsService.permanentlyDeleteReport(
          reportId: reportId,
          collection: collection,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف التقرير نهائياً بنجاح'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الحذف النهائي: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAllReports() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف جميع التقارير؟\n\nهذا الإجراء لا يمكن التراجع عنه وسيتم حذف جميع التقارير النشطة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف الكل', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        await PetReportsService.deleteAllReports();

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف جميع التقارير بنجاح'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الحذف: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }
}

