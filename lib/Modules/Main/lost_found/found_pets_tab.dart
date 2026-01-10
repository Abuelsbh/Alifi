import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../../Widgets/translated_text.dart';
import 'unified_pet_card.dart';

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
        //_buildSearchAndFilter(),
        
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

  // Widget _buildSearchAndFilter() {
  //   return Container(
  //     padding: EdgeInsets.all(16.w),
  //     child: Column(
  //       children: [
  //         // Search Bar
  //         TextField(
  //           controller: _searchController,
  //           onChanged: (_) => _filterPets(),
  //           decoration: InputDecoration(
  //             hintText: 'ابحث عن الحيوانات الموجودة...',
  //             prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12.r),
  //               borderSide: BorderSide.none,
  //             ),
  //             filled: true,
  //             fillColor: Colors.grey[100],
  //           ),
  //         ),
  //
  //         SizedBox(height: 12.h),
  //
  //         // Filter Options
  //         Row(
  //           children: [
  //             Expanded(
  //               child: DropdownButtonFormField<String>(
  //                 value: _selectedPetType,
  //                 hint: const Text('نوع الحيوان'),
  //                 decoration: InputDecoration(
  //                   contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8.r),
  //                     borderSide: BorderSide.none,
  //                   ),
  //                   filled: true,
  //                   fillColor: Colors.grey[100],
  //                 ),
  //                 items: ['كلب', 'قطة', 'أرنب', 'طائر', 'أخرى'].map((type) {
  //                   return DropdownMenuItem(value: type, child: Text(type));
  //                 }).toList(),
  //                 onChanged: (value) {
  //                   setState(() {
  //                     _selectedPetType = value;
  //                   });
  //                   _filterPets();
  //                 },
  //               ),
  //             ),
  //
  //             SizedBox(width: 12.w),
  //
  //             Expanded(
  //               child: DropdownButtonFormField<String>(
  //                 value: _selectedBreed,
  //                 hint: const Text('السلالة'),
  //                 decoration: InputDecoration(
  //                   contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8.r),
  //                     borderSide: BorderSide.none,
  //                   ),
  //                   filled: true,
  //                   fillColor: Colors.grey[100],
  //                 ),
  //                 items: ['جولدن ريتريفر', 'شيرازي', 'سيامي', 'بلدي'].map((breed) {
  //                   return DropdownMenuItem(value: breed, child: Text(breed));
  //                 }).toList(),
  //                 onChanged: (value) {
  //                   setState(() {
  //                     _selectedBreed = value;
  //                   });
  //                   _filterPets();
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
          TranslatedText(
            'lost_found.no_found_pets',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          TranslatedText(
            'lost_found.no_matching_pets',
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
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      itemCount: _filteredPets.length,
      itemBuilder: (context, index) {
        final pet = _filteredPets[index];
        return RepaintBoundary(
          key: ValueKey('found_pet_${pet['id'] ?? index}'),
          child: Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: UnifiedPetCard(
              color: index%2 == 0 ? ThemeClass.of(context).secondaryColor : ThemeClass.of(context).primaryColor,
              pet: pet,
              reportType: 'found',
            ),
          ),
        );
      },
    );
  }
} 