import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/services/pet_stores_service.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../Widgets/translated_text.dart';
import 'store_details_screen.dart';

class PetStoresScreen extends StatefulWidget {
  static const String routeName = '/pet-stores';
  
  const PetStoresScreen({super.key});

  @override
  State<PetStoresScreen> createState() => _PetStoresScreenState();
}

class _PetStoresScreenState extends State<PetStoresScreen> {
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _filteredStores = [];
  List<String> _categories = [];
  List<String> _cities = [];
  
  String _selectedCategory = 'all';
  String _selectedCity = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🏪 Starting to load stores...');
      
      // Test Firebase connection first
      await PetStoresService.testFirebaseConnection();
      
      // Check if collection exists
      await PetStoresService.checkCollectionExists();
      
      final stores = await PetStoresService.getActivePetStores();
      print('🏪 Loaded ${stores.length} stores from Firebase');
      
      if (stores.isNotEmpty) {
        print('🏪 First store data: ${stores.first}');
      }
      
      final categories = await PetStoresService.getAvailableCategories();
      print('📁 Available categories: $categories');
      
      final cities = await PetStoresService.getAvailableCities();
      print('🏙️ Available cities: $cities');

      setState(() {
        _stores = stores;
        _filteredStores = stores;
        _categories = categories;
        _cities = cities;
        _isLoading = false;
      });
      
      print('✅ Stores loaded successfully. UI updated.');
    } catch (e) {
      print('❌ Error loading stores: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterStores() {
    List<Map<String, dynamic>> filtered = _stores;

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((store) => 
        store['category'] == _selectedCategory).toList();
    }

    // Filter by city
    if (_selectedCity != 'all') {
      filtered = filtered.where((store) => 
        store['city'] == _selectedCity).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((store) {
        final name = store['name']?.toString().toLowerCase() ?? '';
        final description = store['description']?.toString().toLowerCase() ?? '';
        final city = store['city']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        
        return name.contains(query) || 
               description.contains(query) ||
               city.contains(query);
      }).toList();
    }

    setState(() {
      _filteredStores = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: BottomNavBarWidget(
        selected: SelectedBottomNavBar.home,
      ),
      appBar: AppBar(
        title: const TranslatedText('home.pet_stores'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Temporary debug button
          IconButton(
            onPressed: () async {
              print('🧪 Creating test store...');
              await PetStoresService.createTestStore();
              _loadStores(); // Refresh
            },
            icon: const Icon(Icons.add_circle),
            tooltip: 'Add Test Store',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStores,
              child: Column(
                children: [
                  _buildSearchAndFilters(),
                  Expanded(
                    child: _filteredStores.isEmpty
                        ? _buildEmptyState()
                        : _buildStoresList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterStores();
              },
              decoration: InputDecoration(
                hintText: Provider.of<AppLanguage>(context).translate('common.search'),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w, 
                  vertical: 12.h,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Filters
          Row(
            children: [
              // Category Filter
              Expanded(
                child: _buildFilterDropdown(
                  value: _selectedCategory,
                  items: [
                    {'value': 'all', 'label': 'common.all'},
                    ..._categories.map((category) => {
                      'value': category,
                      'label': PetStoresService.formatCategoryName(category),
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? 'all';
                    });
                    _filterStores();
                  },
                  hint: 'Category',
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // City Filter
              Expanded(
                child: _buildFilterDropdown(
                  value: _selectedCity,
                  items: [
                    {'value': 'all', 'label': 'common.all'},
                    ..._cities.map((city) => {
                      'value': city,
                      'label': city,
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value ?? 'all';
                    });
                    _filterStores();
                  },
                  hint: 'City',
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
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(fontSize: 14.sp)),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['value'],
              child: Text(
                item['label']!.startsWith('common.') 
                    ? Provider.of<AppLanguage>(context).translate(item['label']!)
                    : item['label']!,
                style: TextStyle(fontSize: 14.sp),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStoresList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredStores.length,
      itemBuilder: (context, index) {
        final store = _filteredStores[index];
        return _buildStoreCard(store);
      },
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final rating = (store['rating'] ?? 4.0).toDouble();
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreDetailsScreen(store: store),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              child: Container(
                height: 160.h,
                width: double.infinity,
                color: AppTheme.primaryGreen.withOpacity(0.1),
                child: store['imageUrl'] != null && store['imageUrl'].isNotEmpty
                    ? Image.network(
                        store['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage(store);
                        },
                      )
                    : _buildPlaceholderImage(store),
              ),
            ),
            
            // Store Info
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Name & Category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store['name'] ?? 'Unknown Store',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightOnSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w, 
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${PetStoresService.getCategoryIcon(store['category'] ?? '')} ${PetStoresService.formatCategoryName(store['category'] ?? '')}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Rating
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < rating.floor()
                              ? Icons.star
                              : index < rating
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: AppTheme.warning,
                          size: 16.sp,
                        );
                      }),
                      SizedBox(width: 4.w),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightOnBackground,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16.sp,
                        color: AppTheme.primaryGreen,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          '${store['city'] ?? 'Unknown City'}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.lightOnBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (store['workingHours'] != null && store['workingHours'].isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16.sp,
                          color: AppTheme.primaryGreen,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            store['workingHours'],
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.lightOnBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (store['description'] != null && store['description'].isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      store['description'].length > 100
                          ? '${store['description'].substring(0, 100)}...'
                          : store['description'],
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.lightOnBackground.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 12.h),
                  
                  // Features
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    children: [
                      if (store['deliveryAvailable'] == true)
                        _buildFeatureChip('🚚 Delivery Available'),
                      if (store['website'] != null && store['website'].isNotEmpty)
                        _buildFeatureChip('🌐 Website'),
                      if (store['phone'] != null && store['phone'].isNotEmpty)
                        _buildFeatureChip('📞 Phone'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(Map<String, dynamic> store) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.3),
            AppTheme.primaryGreen.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Text(
          PetStoresService.getCategoryIcon(store['category'] ?? ''),
          style: TextStyle(fontSize: 48.sp),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🏪',
              style: TextStyle(fontSize: 64.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              _stores.isEmpty 
                  ? 'No stores available yet'
                  : Provider.of<AppLanguage>(context).translate('stores.no_stores_found'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightOnSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _stores.isEmpty 
                  ? 'Pet stores will appear here once they are added by the admin'
                  : Provider.of<AppLanguage>(context).translate('stores.try_different_search'),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.lightOnBackground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            if (_stores.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'all';
                    _selectedCity = 'all';
                    _searchQuery = '';
                    _searchController.clear();
                  });
                  _filterStores();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const TranslatedText('common.clear_filters'),
              ),
            if (_stores.isEmpty)
              ElevatedButton(
                onPressed: _loadStores,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const TranslatedText('common.refresh'),
              ),
          ],
        ),
      ),
    );
  }
} 