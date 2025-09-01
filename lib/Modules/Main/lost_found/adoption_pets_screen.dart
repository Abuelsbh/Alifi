import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/translated_text.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/translated_custom_button.dart';
import 'adoption_pet_details_screen.dart';
import 'post_report_screen.dart';
import 'lost_found_screen.dart';

class AdoptionPetsScreen extends StatefulWidget {
  const AdoptionPetsScreen({super.key});

  @override
  State<AdoptionPetsScreen> createState() => _AdoptionPetsScreenState();
}

class _AdoptionPetsScreenState extends State<AdoptionPetsScreen> {
  List<AdoptionPetModel> _adoptionPets = [];
  bool _isLoading = true;
  String _selectedFilter = 'الكل';
  
  final List<String> _filterOptions = ['الكل', 'كلب', 'قط', 'طائر', 'أرنب', 'أخرى'];

  @override
  void initState() {
    super.initState();
    _loadAdoptionPets();
  }

  Future<void> _loadAdoptionPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('adoption_pets')
          .limit(50)
          .get();

      // Filter and sort manually
      final activeDocs = querySnapshot.docs.where((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          return data['isActive'] == true;
        } catch (e) {
          print('Error filtering doc ${doc.id}: $e');
          return false; // Skip documents with invalid data
        }
      }).toList();

      // Sort by createdAt manually
      activeDocs.sort((a, b) {
        try {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        } catch (e) {
          print('Error sorting docs: $e');
          return 0; // Keep original order if sorting fails
        }
      });

      // Convert to models with error handling
      final pets = <AdoptionPetModel>[];
      for (final doc in activeDocs) {
        try {
          final pet = AdoptionPetModel.fromFirestore(doc);
          pets.add(pet);
        } catch (e) {
          print('Error converting doc ${doc.id} to AdoptionPetModel: $e');
          // Skip this document and continue with others
        }
      }
      
      setState(() {
        _adoptionPets = pets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading adoption pets: $e');
      // Print additional debug info
      print('Error type: ${e.runtimeType}');
      if (e is StateError) {
        print('StateError details: ${e.message}');
      }
      
      setState(() {
        _adoptionPets = []; // Empty list if error
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
              onPressed: _loadAdoptionPets,
            ),
          ),
        );
      }
    }
  }

  List<AdoptionPetModel> get _filteredPets {
    if (_selectedFilter == 'الكل') {
      return _adoptionPets;
    }
    return _adoptionPets.where((pet) => pet.petType == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.primaryGreen,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TranslatedText(
          'adoption.title',
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
            icon: Icon(
              Icons.refresh,
              color: AppTheme.primaryGreen,
            ),
            onPressed: _loadAdoptionPets,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
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
                      backgroundColor: Theme.of(context).colorScheme.background,
                      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryGreen : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryGreen : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Content Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPets.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAdoptionPets,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: _filteredPets.length,
                          itemBuilder: (context, index) {
                            return _buildPetCard(_filteredPets[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PostReportScreen(
                reportType: ReportType.adoption,
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        icon: Icon(
          Icons.pets,
          color: Colors.white,
        ),
        label: TranslatedText(
          'adoption.add_pet',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: 24.h),
          TranslatedText(
            'adoption.no_pets_available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 16.h),
          TranslatedText(
            'adoption.no_pets_subtitle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadAdoptionPets,
            icon: Icon(Icons.refresh),
            label: Text('تحديث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(AdoptionPetModel pet) {
    return CustomCard(
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdoptionPetDetailsScreen(pet: pet),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Pet Image
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                    ),
                    child: pet.photos.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.network(
                              pet.photos.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.pets,
                                  color: AppTheme.primaryGreen,
                                  size: 40.sp,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.pets,
                            color: AppTheme.primaryGreen,
                            size: 40.sp,
                          ),
                  ),
                  
                  SizedBox(width: 16.w),
                  
                  // Pet Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.petName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 16.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${pet.petType} • ${pet.gender} • ${pet.age} سنة',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        if (pet.breed.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.pets,
                                size: 16.sp,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                pet.breed,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                  
                  // Adoption Fee
                  if (pet.adoptionFee > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${pet.adoptionFee.toStringAsFixed(0)} ج.م',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Pet Description
              if (pet.description.isNotEmpty) ...[
                Text(
                  pet.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),
              ],
              
              // Pet Features
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: [
                  if (pet.isVaccinated)
                    _buildFeatureChip('محصن', Icons.medical_services, Colors.green),
                  if (pet.isNeutered)
                    _buildFeatureChip('معقم', Icons.medical_services, Colors.blue),
                  if (pet.goodWithKids)
                    _buildFeatureChip('يحب الأطفال', Icons.child_care, Colors.orange),
                  if (pet.goodWithPets)
                    _buildFeatureChip('يحب الحيوانات', Icons.pets, Colors.purple),
                  if (pet.isHouseTrained)
                    _buildFeatureChip('مدرب منزلياً', Icons.home, Colors.teal),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Contact Info and Posted Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'منشور بواسطة: ${pet.contactName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    _formatDate(pet.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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

  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inMinutes} دقيقة';
    }
  }
} 