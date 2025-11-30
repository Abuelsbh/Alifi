import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/advertisement_service.dart';
import '../core/services/location_service.dart';

// Helper function to build image widget (supports base64 and network images)
Widget _buildAdvertisementImageWidget(String imageUrl, BuildContext context) {
  // Check if image is base64
  if (imageUrl.startsWith('data:image')) {
    try {
      // Extract base64 string from data URI
      final base64String = imageUrl.split(',')[1];
      final imageBytes = base64Decode(base64String);
      
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget(context);
        },
      );
    } catch (e) {
      print('❌ Error decoding base64 image: $e');
      return _buildImageErrorWidget(context);
    }
  } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    // Regular network image
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildImageErrorWidget(context),
    );
  } else {
    // Invalid image URL
    return _buildImageErrorWidget(context);
  }
}

Widget _buildImageErrorWidget(BuildContext context) {
  return Container(
    color: Colors.grey[300],
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_not_supported,
          size: 40.sp,
          color: Colors.grey[600],
        ),
        SizedBox(height: 8.h),
        Text(
          'Image not available',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12.sp,
          ),
        ),
      ],
    ),
  );
}

class AdvertisementCarousel extends StatefulWidget {
  const AdvertisementCarousel({super.key});

  @override
  State<AdvertisementCarousel> createState() => _AdvertisementCarouselState();
}

class _AdvertisementCarouselState extends State<AdvertisementCarousel> {
  int _currentIndex = 0;
  Future<List<Advertisement>>? _advertisementsFuture;

  @override
  void initState() {
    super.initState();
    // Load advertisements once when widget is created - no continuous streams
    _loadAdvertisements();
  }

  void _loadAdvertisements() {
    // Load advertisements once - no continuous stream or polling
    setState(() {
      _advertisementsFuture = AdvertisementService.getActiveAdvertisements();
    });
  }

  // Future<void> _onAdTap(Advertisement ad) async {
  //   // Increment click count
  //   AdvertisementService.incrementAdClick(ad.id);
  //
  //   // Handle click URL if provided
  //   if (ad.clickUrl != null && ad.clickUrl!.isNotEmpty) {
  //     try {
  //       final Uri url = Uri.parse(ad.clickUrl!);
  //       if (await canLaunchUrl(url)) {
  //         await launchUrl(url, mode: LaunchMode.externalApplication);
  //       }
  //     } catch (e) {
  //       print('Error launching URL: $e');
  //     }
  //   }
  // }

  Future<void> _onAdTap(Advertisement ad) async {
    AdvertisementService.incrementAdClick(ad.id);

    if (ad.clickUrl != null && ad.clickUrl!.isNotEmpty) {
      try {
        final Uri url = Uri.parse(ad.clickUrl!);

        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          // fallback
          await launchUrl(url, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        print('Error launching URL: $e');
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder to load advertisements once only
    if (_advertisementsFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Advertisement>>(
      future: _advertisementsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180.h,
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ AdvertisementCarousel: Error: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        final advertisements = snapshot.data ?? [];
        final userLocationId = LocationService.getUserLocation();
        
        print('🎯 AdvertisementCarousel: Building with ${advertisements.length} ads for location: $userLocationId');

        if (advertisements.isEmpty) {
          print('🎯 AdvertisementCarousel: No ads to display for current location');
          return const SizedBox.shrink(); // Don't show anything if no ads
        }

        // Track view for first ad when it loads (only once)
        if (advertisements.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AdvertisementService.incrementAdView(advertisements.first.id);
          });
        }

        return Container(
         // margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            children: [
              // Carousel
              CarouselSlider.builder(
                itemCount: advertisements.length,
                itemBuilder: (context, index, realIndex) {
                  final ad = advertisements[index];
                  return _buildAdCard(ad);
                },
                options: CarouselOptions(
                  height: 180.h,
                  autoPlay: advertisements.length > 1,
                  autoPlayInterval: const Duration(seconds: 5),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  onPageChanged: (index, reason) => _onPageChanged(index, advertisements),
                ),
              ),
              
              // Indicators (only if more than 1 ad)
              if (advertisements.length > 1) ...[
                SizedBox(height: 15.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: advertisements.asMap().entries.map((entry) {
                    final index = entry.key;
                    final isActive = index == _currentIndex;
                    
                    return Container(
                      width: isActive ? 20.w : 8.w,
                      height: 8.h,
                      margin: EdgeInsets.symmetric(horizontal: 3.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        color: isActive 
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _onPageChanged(int index, List<Advertisement> ads) {
    setState(() {
      _currentIndex = index;
    });
    
    // Track view for the new ad
    if (index < ads.length) {
      AdvertisementService.incrementAdView(ads[index].id);
    }
  }

  Widget _buildAdCard(Advertisement ad) {
    return GestureDetector(
      onTap: () => _onAdTap(ad),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.r),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: _buildAdvertisementImageWidget(ad.imageUrl, context),
              ),
              
              // Gradient Overlay (for better text readability)
              if (ad.title != null || ad.description != null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              
              // Text Content
              if (ad.title != null || ad.description != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (ad.title != null)
                          Text(
                            ad.title!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (ad.description != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            ad.description!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.sp,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              
              // Click indicator (if clickUrl is provided)
              if (ad.clickUrl != null && ad.clickUrl!.isNotEmpty)
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 12.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Tap to visit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple Advertisement Widget for single ad display
class AdvertisementCard extends StatelessWidget {
  final Advertisement advertisement;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  const AdvertisementCard({
    super.key,
    required this.advertisement,
    this.onTap,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 150.h,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: _buildAdvertisementImageWidget(advertisement.imageUrl, context),
        ),
      ),
    );
  }
}
