import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/Theme/app_theme.dart';
import '../../core/services/veterinary_service.dart';
import '../../core/Language/translation_service.dart';
import '../../Widgets/translated_text.dart';
import '../../Widgets/custom_button.dart';
import '../../Widgets/custom_textfield_widget.dart';
import 'add_veterinarian_dialog.dart';

class VeterinarianManagementScreen extends StatefulWidget {
  const VeterinarianManagementScreen({super.key});

  @override
  State<VeterinarianManagementScreen> createState() => _VeterinarianManagementScreenState();
}

class _VeterinarianManagementScreenState extends State<VeterinarianManagementScreen> {
  String _searchQuery = '';
  Stream<List<Map<String, dynamic>>>? _veterinariansStream;

  @override
  void initState() {
    super.initState();
    _loadVeterinarians();
  }

  void _loadVeterinarians() {
    _veterinariansStream = VeterinaryService.getAllVeterinariansForAdmin();
  }

  List<Map<String, dynamic>> _filterVeterinarians(List<Map<String, dynamic>> vets) {
    if (_searchQuery.isEmpty) return vets;
    
    return vets.where((vet) {
      final name = vet['name']?.toString().toLowerCase() ?? '';
      final email = vet['email']?.toString().toLowerCase() ?? '';
      final specialization = vet['specialization']?.toString().toLowerCase() ?? '';
      
      return name.contains(_searchQuery.toLowerCase()) ||
             email.contains(_searchQuery.toLowerCase()) ||
             specialization.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏥 Veterinarian Management'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVeterinarians,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVeterinarianDialog,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Veterinarian', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.grey[50],
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search veterinarians...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          // Veterinarians List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _veterinariansStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64.sp,
                          color: Colors.red[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Error loading veterinarians',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.red[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: _loadVeterinarians,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allVets = snapshot.data ?? [];
                final filteredVets = _filterVeterinarians(allVets);

                if (filteredVets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 64.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'No veterinarians found'
                              : 'No results for "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          SizedBox(height: 8.h),
                          Text(
                            'Add your first veterinarian',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: filteredVets.length,
                  itemBuilder: (context, index) {
                    final vet = filteredVets[index];
                    return _buildVeterinarianCard(vet);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVeterinarianCard(Map<String, dynamic> vet) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: (vet['isActive'] == true)
                      ? AppTheme.primaryGreen.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  child: Icon(
                    Icons.local_hospital,
                    color: (vet['isActive'] == true) ? AppTheme.primaryGreen : Colors.grey,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vet['name'],
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.lightOnSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: (vet['isActive'] == true)
                                  ? AppTheme.success.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              (vet['isActive'] == true) ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: (vet['isActive'] == true) ? AppTheme.success : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        vet['specialization'],
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Contact Information
            Row(
              children: [
                Icon(Icons.email, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    vet['email'],
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.phone, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Text(
                  vet['phone'],
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                ),
                const Spacer(),
                Text(
                  'Experience: ${vet['experience']}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editVeterinarian(vet),
                  icon: Icon(Icons.edit, size: 16.sp),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.info,
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () => _toggleVeterinarianStatus(vet),
                  icon: Icon(
                    (vet['isActive'] == true) ? Icons.pause : Icons.play_arrow,
                    size: 16.sp,
                  ),
                  label: Text((vet['isActive'] == true) ? 'Deactivate' : 'Activate'),
                  style: TextButton.styleFrom(
                    foregroundColor: (vet['isActive'] == true) ? AppTheme.warning : AppTheme.success,
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () => _deleteVeterinarian(vet),
                  icon: Icon(Icons.delete, size: 16.sp),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVeterinarianDialog() {
    showDialog(
      context: context,
      builder: (context) => AddVeterinarianDialog(
        onVeterinarianAdded: () {
          // Stream will automatically update
        },
      ),
    );
  }

  void _editVeterinarian(Map<String, dynamic> vet) {
    showDialog(
      context: context,
      builder: (context) => AddVeterinarianDialog(
        veterinarian: vet,
        onVeterinarianAdded: () {
          // Stream will automatically update
        },
      ),
    );
  }

  void _toggleVeterinarianStatus(Map<String, dynamic> vet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vet['isActive'] == true ? 'Deactivate' : 'Activate'} Veterinarian'),
        content: Text(
          'Are you sure you want to ${vet['isActive'] == true ? 'deactivate' : 'activate'} Dr. ${vet['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                final newStatus = !(vet['isActive'] == true);
                await VeterinaryService.toggleVeterinarianStatus(vet['id'], newStatus);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Dr. ${vet['name']} has been ${newStatus ? 'activated' : 'deactivated'}',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(vet['isActive'] == true ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _deleteVeterinarian(Map<String, dynamic> vet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Veterinarian'),
        content: Text('Are you sure you want to delete Dr. ${vet['name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await VeterinaryService.deleteVeterinarian(vet['id']);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dr. ${vet['name']} has been deleted'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting veterinarian: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 