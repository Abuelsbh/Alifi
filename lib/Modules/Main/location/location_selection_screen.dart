import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/services/location_service.dart';
import '../../../Models/location_model.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/translation_service.dart';
import '../../../Utilities/text_style_helper.dart';
import '../../../Utilities/theme_helper.dart';
import '../home/home_screen.dart';

class LocationSelectionScreen extends StatefulWidget {
  static const String routeName = '/LocationSelection';

  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  List<LocationModel> _locations = [];
  bool _isLoading = true;
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadSelectedLocation();
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await LocationService.getActiveLocations();
      if (mounted) {
        setState(() {
          _locations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSelectedLocation() async {
    final locationId = LocationService.getUserLocation();
    if (mounted) {
      setState(() {
        _selectedLocationId = locationId;
      });
    }
  }

  Future<void> _selectLocation(LocationModel location) async {
    // Prevent multiple taps
    if (!mounted) return;
    
    try {
      print('📍 Selecting location: ${location.name} (${location.id})');
      
      // Validate location ID
      if (location.id.isEmpty) {
        throw Exception('Invalid location ID');
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12.w),
              Text('Saving location...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Save location
      final success = await LocationService.saveUserLocation(location.id);
      print('📍 Save location result: $success');
      
      if (!success) {
        throw Exception('Failed to save location to cache');
      }

      // Verify it was saved
      final savedLocationId = LocationService.getUserLocation();
      print('📍 Verified saved location: $savedLocationId');
      
      if (savedLocationId != location.id) {
        throw Exception('Location was not saved correctly');
      }

      if (!mounted) return;

      // Update UI
      setState(() {
        _selectedLocationId = location.id;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location saved successfully!'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 1),
        ),
      );

      // Wait a bit then navigate back
      await Future.delayed(Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      // Navigate back to previous screen (home screen) with result
      Navigator.of(context).pop(location.id);
      
    } catch (e, stackTrace) {
      print('❌ Error saving location: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save location: ${e.toString()}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.error,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _selectLocation(location),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            
            // Content Section
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: ThemeClass.of(context).primaryColor, // Orange
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: 10.w),
          // Title
          Expanded(
            child: Text(
              TranslationService.instance.translate('location.title') ?? 'Location',
              style: TextStyleHelper.of(context).s28InterTextStyle().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: ThemeClass.of(context).primaryColor,
        ),
      );
    }

    if (_locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              TranslationService.instance.translate('location.no_locations') ?? 'No locations available',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Text(
              TranslationService.instance.translate('location.explore_service_area') ?? 'Explore our service area',
              style: TextStyleHelper.of(context).s18RegTextStyle.copyWith(
                color: ThemeClass.of(context).secondaryColor, // Green
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Locations List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                final location = _locations[index];
                final isSelected = _selectedLocationId == location.id;
                // Alternate between orange and green
                final isOrange = index % 2 == 0;
                final textColor = isOrange
                    ? ThemeClass.of(context).primaryColor // Orange
                    : ThemeClass.of(context).secondaryColor; // Green
                final iconColor = textColor;

                return _buildLocationItem(
                  location: location,
                  textColor: textColor,
                  iconColor: iconColor,
                  isSelected: isSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem({
    required LocationModel location,
    required Color textColor,
    required Color iconColor,
    required bool isSelected,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectLocation(location),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? iconColor
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12.r),
              color: isSelected
                  ? iconColor.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                // Map pin icon
                Icon(
                  Icons.location_on,
                  color: iconColor,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                // Location name
                Expanded(
                  child: Text(
                    location.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                ),
                // Chevron icon
                Icon(
                  Icons.chevron_right,
                  color: iconColor,
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

