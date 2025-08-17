import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';
import '../../../Widgets/translated_text.dart';
import '../../../Models/pet_report_model.dart';

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
  List<FoundPetModel> _foundPets = [];
  List<FoundPetModel> _filteredPets = [];

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
      // TODO: Load from service
      // Mock data for now
      await Future.delayed(const Duration(seconds: 1));
      _foundPets = [
        FoundPetModel(
          id: '1',
          userId: 'user3',
          petType: 'Dog',
          breed: 'Labrador',
          color: 'Black',
          photos: [],
          description: 'Found a friendly black Labrador near the park. Very well-behaved and seems to be lost.',
          location: const GeoPoint(40.7589, -73.9851),
          address: 'Central Park, New York',
          foundDate: DateTime.now().subtract(const Duration(hours: 3)),
          contactPhone: '+1234567892',
          contactName: 'Mike Johnson',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        FoundPetModel(
          id: '2',
          userId: 'user4',
          petType: 'Cat',
          breed: 'Maine Coon',
          color: 'Orange',
          photos: [],
          description: 'Found an orange Maine Coon cat in my backyard. Very friendly and seems to be looking for its owner.',
          location: const GeoPoint(40.7505, -73.9934),
          address: 'Downtown Manhattan',
          foundDate: DateTime.now().subtract(const Duration(days: 1)),
          contactPhone: '+1234567893',
          contactName: 'Sarah Wilson',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      _filteredPets = _foundPets;
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPets() {
    setState(() {
      _filteredPets = _foundPets.where((pet) {
        bool matchesSearch = _searchController.text.isEmpty ||
            pet.description.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            pet.address.toLowerCase().contains(_searchController.text.toLowerCase());

        bool matchesPetType = _selectedPetType == null || pet.petType == _selectedPetType;
        bool matchesBreed = _selectedBreed == null || pet.breed == _selectedBreed;

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
            onChanged: (value) => _filterPets(),
            decoration: InputDecoration(
              hintText: 'lost_found.search_placeholder',
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppTheme.primaryGreen),
                      onPressed: () {
                        _searchController.clear();
                        _filterPets();
                      },
                    )
                  : null,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Filter Row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPetType,
                  decoration: InputDecoration(
                    labelText: 'lost_found.filter_by_type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: TranslatedText('lost_found.all_types'),
                    ),
                    ...['Dog', 'Cat', 'Bird', 'Other'].map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    )),
                  ],
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
                  decoration: InputDecoration(
                    labelText: 'lost_found.filter_by_breed',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: TranslatedText('lost_found.all_breeds'),
                    ),
                    ...['Golden Retriever', 'Labrador', 'Persian', 'Siamese', 'Other'].map((breed) => DropdownMenuItem(
                      value: breed,
                      child: Text(breed),
                    )),
                  ],
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

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
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
            Icons.search_off,
            size: 64.sp,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No found pets',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
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
        final pet = _filteredPets[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildPetCard(pet),
        );
      },
    );
  }

  Widget _buildPetCard(FoundPetModel pet) {
    return CustomCard(
      onTap: () {
        // TODO: Navigate to pet details
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.pets,
                  color: AppTheme.primaryGreen,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Found ${pet.petType}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${pet.breed} • ${pet.color}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'FOUND',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            pet.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16.sp,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  pet.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16.sp,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
              SizedBox(width: 4.w),
              Text(
                _formatTimeAgo(pet.foundDate),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Contact',
                type: ButtonType.text,
                onPressed: () {
                  _showContactInfo(pet);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showContactInfo(FoundPetModel pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: TranslatedText('lost_found.contact_information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText('lost_found.name: ${pet.contactName}'),
            SizedBox(height: 8.h),
            TranslatedText('lost_found.phone: ${pet.contactPhone}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TranslatedText('lost_found.close'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
} 