import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/translated_text.dart';
import '../../../Widgets/custom_card.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../add_animal/add_animal_screen.dart';
import 'breeding_pet_details_screen.dart';

class BreedingPetsScreen extends StatefulWidget {
  const BreedingPetsScreen({super.key});

  @override
  State<BreedingPetsScreen> createState() => _BreedingPetsScreenState();
}

class _BreedingPetsScreenState extends State<BreedingPetsScreen> {
  List<BreedingPetModel> _breedingPets = [];
  bool _isLoading = true;
  String _selectedFilter = 'الكل'; // All, Dog, Cat, etc.

  final List<String> _filterOptions = ['الكل', 'كلب', 'قط', 'أخرى'];

  @override
  void initState() {
    super.initState();
    _loadBreedingPets();
  }

  Future<void> _loadBreedingPets() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Listen to real-time updates
      PetReportsService.getBreedingPetsStream().listen((pets) {
        if (mounted) {
          setState(() {
            _breedingPets = pets;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading breeding pets: $e');
      setState(() {
        _breedingPets = []; // Empty list if error
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات. يرجى المحاولة مرة أخرى.'),
            backgroundColor: AppTheme.error,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: _loadBreedingPets,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: TranslatedText('breeding.title'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryGreen,
                  ),
                );
              },
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredPets().isEmpty
                    ? _buildEmptyState()
                    : _buildPetsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAnimalScreen(
                reportType: ReportType.breeding,
                title: 'إضافة حيوان للتزاوج',
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
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
            size: 80.sp,
            color: AppTheme.primaryGreen.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          TranslatedText(
            'breeding.no_pets_available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 8.h),
          TranslatedText(
            'breeding.no_pets_subtitle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _loadBreedingPets,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: TranslatedText('common.refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    final filteredPets = _getFilteredPets();
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredPets.length,
      itemBuilder: (context, index) {
        final pet = filteredPets[index];
        return _buildPetCard(pet);
      },
    );
  }

  Widget _buildPetCard(BreedingPetModel pet) {
    return CustomCard(
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BreedingPetDetailsScreen(pet: pet),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Pet Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 80.w,
                  height: 80.h,
                  child: pet.photos.isNotEmpty
                      ? Image.network(
                          pet.photos.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              child: Icon(
                                Icons.pets,
                                color: AppTheme.primaryGreen,
                                size: 30.sp,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          child: Icon(
                            Icons.pets,
                            color: AppTheme.primaryGreen,
                            size: 30.sp,
                          ),
                        ),
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // Pet Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.petName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        if (pet.isRegistered)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'مسجل',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          '${pet.petType} • ${pet.breed}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          width: 4.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '${pet.age} سنة',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16.sp,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            pet.address,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
              
              // Breeding Fee
              if (pet.breedingFee > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${pet.breedingFee.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'مجاني',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<BreedingPetModel> _getFilteredPets() {
    if (_selectedFilter == 'الكل') {
      return _breedingPets;
    }
    return _breedingPets.where((pet) => pet.petType == _selectedFilter).toList();
  }
} 