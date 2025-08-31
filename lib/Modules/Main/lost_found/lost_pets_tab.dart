import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/pet_reports_service.dart';
import 'unified_pet_card.dart';

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
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      itemCount: _filteredPets.length,
                      itemBuilder: (context, index) {
                        final pet = _filteredPets[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: UnifiedPetCard(
                            pet: pet,
                            reportType: 'lost',
                          ),
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
} 