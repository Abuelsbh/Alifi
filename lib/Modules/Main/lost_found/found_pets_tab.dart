import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';
import 'pet_report_details_screen.dart';

class FoundPetsTab extends StatefulWidget {
  const FoundPetsTab({super.key});

  @override
  State<FoundPetsTab> createState() => _FoundPetsTabState();
}

class _FoundPetsTabState extends State<FoundPetsTab> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedPetType;
  String? _selectedBreed;
  bool _isLoading = false;
  List<Map<String, dynamic>> _foundPets = [];
  List<Map<String, dynamic>> _filteredPets = [];

  @override
  void initState() {
    super.initState();
    _loadFoundPets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFoundPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Listen to real-time found pets stream
      PetReportsService.getFoundPetsStream().listen((foundPets) {
        if (mounted) {
          setState(() {
            _foundPets = foundPets;
            _filterPets();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading found pets: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPets() {
    setState(() {
      _filteredPets = _foundPets.where((pet) {
        final petDetails = pet['petDetails'] as Map<String, dynamic>? ?? {};
        final petName = petDetails['name'] ?? '';
        final petType = petDetails['type'] ?? '';
        final breed = petDetails['breed'] ?? '';
        final description = pet['description'] ?? '';
        
        bool matchesSearch = _searchController.text.isEmpty ||
            petName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            petType.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            breed.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            description.toLowerCase().contains(_searchController.text.toLowerCase());

        bool matchesPetType = _selectedPetType == null || petType == _selectedPetType;
        bool matchesBreed = _selectedBreed == null || breed == _selectedBreed;

        return matchesSearch && matchesPetType && matchesBreed;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Section
        _buildSearchAndFilter(),
        
        // Results
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPets.isEmpty
                  ? _buildEmptyState()
                  : _buildPetsList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (_) => _filterPets(),
            decoration: InputDecoration(
              hintText: 'ابحث عن الحيوانات الموجودة...',
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // Filter Options
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPetType,
                  hint: const Text('نوع الحيوان'),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: ['كلب', 'قطة', 'أرنب', 'طائر', 'أخرى'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPetType = value;
                    });
                    _filterPets();
                  },
                ),
              ),
              
              SizedBox(width: 12.w),
              
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedBreed,
                  hint: const Text('السلالة'),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: ['جولدن ريتريفر', 'شيرازي', 'سيامي', 'بلدي'].map((breed) {
                    return DropdownMenuItem(value: breed, child: Text(breed));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBreed = value;
                    });
                    _filterPets();
                  },
                ),
              ),
            ],
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
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد حيوانات موجودة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'لم يتم العثور على أي حيوانات مطابقة للبحث',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _filteredPets.length,
      itemBuilder: (context, index) {
        return _buildPetCard(_filteredPets[index]);
      },
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final petDetails = pet['petDetails'] as Map<String, dynamic>? ?? {};
    final petName = petDetails['name'] ?? 'حيوان موجود';
    final petType = petDetails['type'] ?? 'غير محدد';
    final breed = petDetails['breed'] ?? '';
    final color = petDetails['color'] ?? '';
    final foundLocation = pet['foundLocation'] ?? pet['address'] ?? 'موقع غير محدد';
    final foundDate = pet['foundDate'] ?? pet['createdAt'];
    final isInShelter = pet['isInShelter'] ?? false;
    final imageUrls = pet['imageUrls'] as List<dynamic>? ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: CustomCard(
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
                                  Icon(Icons.pets, size: 40.sp, color: AppTheme.success),
                            ),
                          )
                        : Icon(Icons.pets, size: 40.sp, color: AppTheme.success),
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
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'موجود',
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
                            color: AppTheme.success,
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
                                foundLocation.isNotEmpty ? foundLocation : 'موقع غير محدد',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (isInShelter) ...[
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppTheme.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'في مأوى آمن',
                              style: TextStyle(
                                color: AppTheme.info,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              Text(
                pet['description'] ?? 'لا يوجد وصف',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12.h),
              
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'تفاصيل',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetReportDetailsScreen(report: pet),
                          ),
                        );
                      },
                      backgroundColor: AppTheme.success,
                      textColor: Colors.white,
                      
                      height: 36.h,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CustomButton(
                      text: 'تواصل',
                      onPressed: () {
                        // TODO: Implement contact functionality
                      },
                      backgroundColor: AppTheme.primaryOrange,
                      textColor: Colors.white,
                      
                      height: 36.h,
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
} 