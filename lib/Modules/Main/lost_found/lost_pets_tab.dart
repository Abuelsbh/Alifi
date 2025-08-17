import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';
import '../../../Models/pet_report_model.dart';

class LostPetsTab extends StatefulWidget {
  const LostPetsTab({super.key});

  @override
  State<LostPetsTab> createState() => _LostPetsTabState();
}

class _LostPetsTabState extends State<LostPetsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedPetType = 'All';
  String _selectedBreed = 'All';
  bool _isLoading = false;
  List<LostPetModel> _lostPets = [];
  List<LostPetModel> _filteredPets = [];

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
      // TODO: Load from service
      // Mock data for now
      await Future.delayed(const Duration(seconds: 1));
      _lostPets = [
        LostPetModel(
          id: '1',
          userId: 'user1',
          petName: 'Max',
          petType: 'Dog',
          breed: 'Golden Retriever',
          age: 3,
          gender: 'Male',
          color: 'Golden',
          photos: [],
          description: 'Lost my 3-year-old Golden Retriever named Max in Central Park area. Please help!',
          location: const GeoPoint(40.7589, -73.9851),
          address: 'Central Park, New York',
          lostDate: DateTime.now().subtract(const Duration(hours: 2)),
          contactPhone: '+1234567890',
          contactName: 'John Doe',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        LostPetModel(
          id: '2',
          userId: 'user2',
          petName: 'Luna',
          petType: 'Cat',
          breed: 'Persian',
          age: 2,
          gender: 'Female',
          color: 'White',
          photos: [],
          description: 'Lost my white Persian cat Luna. She is very friendly and responds to her name.',
          location: const GeoPoint(40.7505, -73.9934),
          address: 'Downtown Manhattan',
          lostDate: DateTime.now().subtract(const Duration(days: 1)),
          contactPhone: '+1234567891',
          contactName: 'Jane Smith',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      _filteredPets = _lostPets;
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
      _filteredPets = _lostPets.where((pet) {
        bool matchesSearch = _searchController.text.isEmpty ||
            pet.petName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            pet.description.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            pet.address.toLowerCase().contains(_searchController.text.toLowerCase());

        bool matchesPetType = _selectedPetType == 'All' || pet.petType == _selectedPetType;
        bool matchesBreed = _selectedBreed == 'All' || pet.breed == _selectedBreed;

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
              hintText: 'Search lost pets...',
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
                child: _buildFilterDropdown(
                  value: _selectedPetType,
                  items: ['All', 'Dog', 'Cat', 'Bird', 'Other'],
                  onChanged: (value) {
                    setState(() {
                      _selectedPetType = value!;
                    });
                    _filterPets();
                  },
                  label: 'Pet Type',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildFilterDropdown(
                  value: _selectedBreed,
                  items: ['All', 'Golden Retriever', 'Persian', 'Labrador', 'Siamese'],
                  onChanged: (value) {
                    setState(() {
                      _selectedBreed = value!;
                    });
                    _filterPets();
                  },
                  label: 'Breed',
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
            'No lost pets found',
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

  Widget _buildPetCard(LostPetModel pet) {
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
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.pets,
                  color: AppTheme.primaryOrange,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
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
                    Text(
                      '${pet.breed} • ${pet.age} years old • ${pet.gender}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      pet.color,
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
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'LOST',
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
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
                _formatTimeAgo(pet.lostDate),
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

  void _showContactInfo(LostPetModel pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${pet.contactName}'),
            SizedBox(height: 8.h),
            Text('Phone: ${pet.contactPhone}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
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