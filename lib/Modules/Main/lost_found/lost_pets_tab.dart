import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';
import '../../../core/services/pet_reports_service.dart';
import 'pet_report_details_screen.dart';

class LostPetsTab extends StatefulWidget {
  const LostPetsTab({super.key});

  @override
  State<LostPetsTab> createState() => _LostPetsTabState();
}

class _LostPetsTabState extends State<LostPetsTab> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedPetType;
  String? _selectedBreed;
  bool _isLoading = false;
  List<Map<String, dynamic>> _lostPets = [];
  List<Map<String, dynamic>> _filteredPets = [];

  @override
  void initState() {
    super.initState();
    _loadLostPets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLostPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load lost pets with real-time stream
      PetReportsService.getLostPetsStream().listen((pets) {
        if (mounted) {
          setState(() {
            _lostPets = pets;
            _filteredPets = pets;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading lost pets: $e');
    }
  }

  void _filterPets() {
    setState(() {
      _filteredPets = _lostPets.where((pet) {
        final query = _searchController.text.toLowerCase();
        final petName = (pet['petDetails']?['name'] ?? pet['petName'] ?? '').toString().toLowerCase();
        final petType = (pet['petDetails']?['type'] ?? pet['petType'] ?? '').toString().toLowerCase();
        final breed = (pet['petDetails']?['breed'] ?? pet['breed'] ?? '').toString().toLowerCase();
        
        bool matchesQuery = query.isEmpty || 
            petName.contains(query) || 
            petType.contains(query) || 
            breed.contains(query);
            
        bool matchesPetType = _selectedPetType == null || 
            petType == _selectedPetType!.toLowerCase();
            
        bool matchesBreed = _selectedBreed == null || 
            breed.contains(_selectedBreed!.toLowerCase());
            
        return matchesQuery && matchesPetType && matchesBreed;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filters
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (value) => _filterPets(),
                decoration: InputDecoration(
                  hintText: 'البحث عن حيوان مفقود...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              
              SizedBox(height: 12.h),
              
              // Filter chips
              Row(
                children: [
                  // Pet type filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPetType,
                      hint: const Text('نوع الحيوان'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'قط', child: Text('قط')),
                        DropdownMenuItem(value: 'كلب', child: Text('كلب')),
                        DropdownMenuItem(value: 'طائر', child: Text('طائر')),
                        DropdownMenuItem(value: 'أرنب', child: Text('أرنب')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPetType = value;
                          _filterPets();
                        });
                      },
                    ),
                  ),
                  
                  SizedBox(width: 8.w),
                  
                  // Breed filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedBreed,
                      hint: const Text('السلالة'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'فارسي', child: Text('فارسي')),
                        DropdownMenuItem(value: 'جيرمان', child: Text('جيرمان')),
                        DropdownMenuItem(value: 'لابرادور', child: Text('لابرادور')),
                        DropdownMenuItem(value: 'مختلط', child: Text('مختلط')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBreed = value;
                          _filterPets();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Pets List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPets.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _filteredPets.length,
                      itemBuilder: (context, index) {
                        final pet = _filteredPets[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildPetCard(pet),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_outlined,
            size: 64.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد حيوانات مفقودة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'جرب تعديل البحث أو الفلاتر',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final petName = pet['petDetails']?['name'] ?? pet['petName'] ?? 'حيوان مفقود';
    final petType = pet['petDetails']?['type'] ?? pet['petType'] ?? 'غير محدد';
    final breed = pet['petDetails']?['breed'] ?? pet['breed'] ?? '';
    final color = pet['petDetails']?['color'] ?? pet['color'] ?? '';
    final lastSeenLocation = pet['lastSeenLocation'] ?? pet['address'] ?? 'موقع غير محدد';
    final lastSeenDate = pet['lastSeenDate'] ?? pet['createdAt'];
    final reward = pet['reward'] ?? 0;
    final isUrgent = pet['isUrgent'] ?? false;
    final imageUrls = pet['imageUrls'] as List<dynamic>? ?? [];

    return CustomCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetReportDetailsScreen(report: pet),
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
                // Pet image
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
                
                SizedBox(width: 12.w),
                
                // Pet info
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
                            ),
                          ),
                          if (isUrgent)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'عاجل',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$petType${breed.isNotEmpty ? ' - $breed' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      if (color.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'اللون: $color',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14.sp, color: Colors.grey[600]),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              lastSeenLocation.isNotEmpty ? lastSeenLocation : 'موقع غير محدد',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (reward > 0) ...[
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.monetization_on, size: 14.sp, color: AppTheme.primaryOrange),
                            SizedBox(width: 4.w),
                            Text(
                              'مكافأة: $reward جنيه',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'اتصال',
                    onPressed: () {
                      // TODO: Implement call functionality
                    },
                    backgroundColor: AppTheme.primaryGreen,
                    textColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: CustomButton(
                    text: 'رسالة',
                    onPressed: () {
                      // TODO: Implement message functionality
                    },
                    backgroundColor: AppTheme.primaryOrange,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 