import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
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
      
      final stores = await PetStoresService.getActivePetStoresForUserLocation();
      print('🏪 Loaded ${stores.length} stores for user location');
      
      if (stores.isNotEmpty) {
        print('🏪 First store data: ${stores.first}');
      }
      
      final categories = PetStoresService.getCategoriesFromStores(stores);
      print('📁 Available categories: $categories');
      
      final cities = PetStoresService.getCitiesFromStores(stores);
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

    // Filter by city (canonical key, see PetStoresService.cityCanonical)
    if (_selectedCity != 'all') {
      filtered = filtered
          .where((store) => PetStoresService.cityCanonical(store) == _selectedCity)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((store) {
        const textKeys = [
          'name',
          'nameEn',
          'nameAr',
          'nameHe',
          'description',
          'descriptionEn',
          'descriptionAr',
          'descriptionHe',
          'city',
          'cityEn',
          'cityAr',
          'cityHe',
        ];
        for (final k in textKeys) {
          final v = store[k]?.toString().toLowerCase() ?? '';
          if (v.contains(query)) return true;
        }
        return false;
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
        titleTextStyle: TextStyleHelper.of(context).s22RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
        centerTitle: true,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Temporary debug button
          // IconButton(
          //   onPressed: () async {
          //     print('🧪 Creating test store...');
          //     await PetStoresService.createTestStore();
          //     _loadStores(); // Refresh
          //   },
          //   icon: const Icon(Icons.add_circle),
          //   tooltip: 'Add Test Store',
          // ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStores,
              child: Column(
                children: [
                 // _buildSearchAndFilters(),
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
                      'label': PetStoresService.cityLabelForCanonical(
                        _stores,
                        city,
                        Provider.of<AppLanguage>(context).appLang.name,
                      ),
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
    final lang = Provider.of<AppLanguage>(context).appLang.name;
    final storeName =
        PetStoresService.storeLocalized(store, lang, 'name');
    final storeCity =
        PetStoresService.storeLocalized(store, lang, 'city');
    final storeAddress =
        PetStoresService.storeLocalized(store, lang, 'address');
    final storeDescription =
        PetStoresService.storeLocalized(store, lang, 'description');
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
                    ? CachedNetworkImage(
                        imageUrl: store['imageUrl'],
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        memCacheHeight: 320,
                        maxWidthDiskCache: 800,
                        maxHeightDiskCache: 600,
                        placeholder: (context, url) => Container(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
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
                          storeName.isNotEmpty ? storeName : 'Unknown Store',
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
                  
                  // Location with Google Maps link
                  if (storeAddress.isNotEmpty)
                    InkWell(
                      onTap: () => _openMap(store, storeAddress, storeCity),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16.sp,
                            color: AppTheme.primaryGreen,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              '$storeAddress, ${storeCity.isNotEmpty ? storeCity : 'Unknown City'}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppTheme.primaryGreen,
                                decoration: TextDecoration.underline,
                                decorationColor: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            size: 14.sp,
                            color: AppTheme.primaryGreen,
                          ),
                        ],
                      ),
                    )
                  else
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
                            storeCity.isNotEmpty ? storeCity : 'Unknown City',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.lightOnBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  if (_hasWorkingHours(store['workingHours'])) ...[
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
                            _formatWorkingHours(store['workingHours']),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.lightOnBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (storeDescription.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      storeDescription.length > 100
                          ? '${storeDescription.substring(0, 100)}...'
                          : storeDescription,
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

  // Helper function to format working hours
  String _formatWorkingHours(dynamic workingHours) {
    if (workingHours == null) return '';
    
    // Legacy format: string
    if (workingHours is String) {
      return workingHours;
    }
    
    // New format: Map with days
    if (workingHours is Map) {
      final dayNames = {
        'saturday': 'Sat',
        'sunday': 'Sun',
        'monday': 'Mon',
        'tuesday': 'Tue',
        'wednesday': 'Wed',
        'thursday': 'Thu',
        'friday': 'Fri',
      };
      
      final arabicDayNames = {
        'saturday': 'السبت',
        'sunday': 'الأحد',
        'monday': 'الإثنين',
        'tuesday': 'الثلاثاء',
        'wednesday': 'الأربعاء',
        'thursday': 'الخميس',
        'friday': 'الجمعة',
      };
      
      final days = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
      final formattedDays = <String>[];
      
      for (final day in days) {
        final dayData = workingHours[day];
        if (dayData is Map) {
          if (dayData['closed'] == true) {
            formattedDays.add('${dayNames[day]}: Closed');
          } else if (dayData['hours'] != null && dayData['hours'].toString().isNotEmpty) {
            formattedDays.add('${dayNames[day]}: ${dayData['hours']}');
          }
        }
      }
      
      if (formattedDays.isEmpty) return '';
      if (formattedDays.length <= 2) {
        return formattedDays.join(', ');
      }
      return formattedDays.take(2).join(', ') + '...';
    }
    
    return '';
  }
  
  // Helper function to check if working hours exist
  bool _hasWorkingHours(dynamic workingHours) {
    if (workingHours == null) return false;
    
    if (workingHours is String) {
      return workingHours.isNotEmpty;
    }
    
    if (workingHours is Map) {
      final days = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
      for (final day in days) {
        final dayData = workingHours[day];
        if (dayData is Map) {
          if (dayData['closed'] == true || 
              (dayData['hours'] != null && dayData['hours'].toString().isNotEmpty)) {
            return true;
          }
        }
      }
    }
    
    return false;
  }

  // Helper function to open Google Maps
  Future<void> _openMap(
    Map<String, dynamic> store,
    String address,
    String city,
  ) async {
    final addressQuery = '$address, $city';
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addressQuery)}',
    );
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      print('Error opening map: $e');
    }
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