import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/advertisement_service.dart';
import '../generated/assets.dart';

class AdvertisementCarousel extends StatefulWidget {
  const AdvertisementCarousel({super.key});

  @override
  State<AdvertisementCarousel> createState() => _AdvertisementCarouselState();
}

class _AdvertisementCarouselState extends State<AdvertisementCarousel> {
  List<Advertisement> _advertisements = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAdvertisements();
  }

  Future<void> _loadAdvertisements() async {
    try {
      print('🎯 AdvertisementCarousel: Loading advertisements...');
      final ads = await AdvertisementService.getActiveAdvertisements();
      print('🎯 AdvertisementCarousel: Received ${ads.length} advertisements');
      
      if (mounted) {
        setState(() {
          _advertisements = ads;
          _isLoading = false;
        });
        
        print('🎯 AdvertisementCarousel: State updated with ${ads.length} ads');
        
        // Track views for visible ads
        if (ads.isNotEmpty) {
          print('🎯 AdvertisementCarousel: Tracking view for first ad: ${ads.first.id}');
          AdvertisementService.incrementAdView(ads.first.id);
        }
      }
    } catch (e) {
      print('❌ AdvertisementCarousel: Error loading ads: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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


  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Track view for the new ad
    if (index < _advertisements.length) {
      AdvertisementService.incrementAdView(_advertisements[index].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎯 AdvertisementCarousel: Building with ${_advertisements.length} ads, loading: $_isLoading');
    
    if (_isLoading) {
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

    if (_advertisements.isEmpty) {
      print('🎯 AdvertisementCarousel: No ads to display, returning empty widget');
      return const SizedBox.shrink(); // Don't show anything if no ads
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        children: [
          // Carousel

          CarouselSlider.builder(
            itemCount: _advertisements.length,
            itemBuilder: (context, index, realIndex) {
              final ad = _advertisements[index];
              return _buildAdCard(ad);
            },
            options: CarouselOptions(
              height: 180.h,
              autoPlay: _advertisements.length > 1,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              onPageChanged: (index, reason) => _onPageChanged(index),
            ),
          ),
          
          // Indicators (only if more than 1 ad)
          if (_advertisements.length > 1) ...[
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _advertisements.asMap().entries.map((entry) {
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
          if(_advertisements.isEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              height: 200.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: Stack(
                  children: [
                    // Cat Image Background
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Color(0xFFFF914C), // Orange background
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24.r),
                          topRight: Radius.circular(24.r),
                        ),
                        child: Image.asset(
                          Assets.imagesLostAnimal,
                          fit: BoxFit.cover, // makes sure image fills area properly
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
        ],
      ),
    );
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
                child: CachedNetworkImage(
                  imageUrl: ad.imageUrl,
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
                  errorWidget: (context, url, error) => Container(
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
                  ),
                ),
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
          child: CachedNetworkImage(
            imageUrl: advertisement.imageUrl,
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
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.image_not_supported,
                size: 30.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
