import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class PerformanceHelper {
  // Optimized image loading with caching and shimmer effect
  static Widget buildOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      imageBuilder: (context, imageProvider) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            image: DecorationImage(
              image: imageProvider,
              fit: fit,
            ),
          ),
        );
      },
      placeholder: (context, url) {
        return placeholder ?? _buildShimmerPlaceholder(width, height, borderRadius);
      },
      errorWidget: (context, url, error) {
        return errorWidget ?? _buildErrorWidget(width, height, borderRadius);
      },
      memCacheWidth: (width ?? 200.w).toInt(),
      memCacheHeight: (height ?? 200.h).toInt(),
      maxWidthDiskCache: 1024,
      maxHeightDiskCache: 1024,
    );
  }

  // Shimmer loading effect
  static Widget _buildShimmerPlaceholder(double? width, double? height, BorderRadius? borderRadius) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  // Error widget for failed image loads
  static Widget _buildErrorWidget(double? width, double? height, BorderRadius? borderRadius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.error_outline,
        color: Colors.grey[400],
        size: 24.sp,
      ),
    );
  }

  // Optimized list view with pagination
  static Widget buildOptimizedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    int? semanticChildCount,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      semanticChildCount: semanticChildCount,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }

  // Optimized grid view with pagination
  static Widget buildOptimizedGridView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    required int crossAxisCount,
    double crossAxisSpacing = 0.0,
    double mainAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }

  // Debounced function for search
  static Function debounce(Function func, Duration wait) {
    Timer? timer;
    return (List<dynamic> args) {
      timer?.cancel();
      timer = Timer(wait, () => func(args));
    };
  }

  // Throttled function for scroll events
  static Function throttle(Function func, Duration wait) {
    DateTime? lastRun;
    return (List<dynamic> args) {
      final now = DateTime.now();
      if (lastRun == null || now.difference(lastRun!) >= wait) {
        lastRun = now;
        func(args);
      }
    };
  }

  // Memory efficient text widget
  static Widget buildOptimizedText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    bool softWrap = true,
  }) {
    return SelectableText(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      enableInteractiveSelection: false,
    );
  }

  // Optimized button with loading state
  static Widget buildOptimizedButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? backgroundColor,
    Color? textColor,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8.r),
          ),
          padding: padding,
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Colors.white,
                  ),
                ),
              )
            : Text(text),
      ),
    );
  }

  // Optimized card widget
  static Widget buildOptimizedCard({
    required Widget child,
    Color? color,
    double? elevation,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Card(
      color: color,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12.r),
      ),
      margin: margin,
      child: Padding(
        padding: padding ?? EdgeInsets.all(16.w),
        child: child,
      ),
    );
  }

  // Memory efficient scroll view
  static Widget buildOptimizedScrollView({
    required Widget child,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool reverse = false,
    ScrollPhysics? physics,
    bool primary = true,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return SingleChildScrollView(
      controller: controller,
      padding: padding,
      reverse: reverse,
      physics: physics,
      primary: primary,
      keyboardDismissBehavior: keyboardDismissBehavior,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  // Optimized animated container
  static Widget buildOptimizedAnimatedContainer({
    required Widget child,
    Duration? duration,
    Curve? curve,
    double? width,
    double? height,
    Color? color,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BoxDecoration? decoration,
  }) {
    return AnimatedContainer(
      duration: duration ?? const Duration(milliseconds: 300),
      curve: curve ?? Curves.easeInOut,
      width: width,
      height: height,
      color: color,
      padding: padding,
      margin: margin,
      decoration: decoration?.copyWith(
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }

  // Memory efficient future builder
  static Widget buildOptimizedFutureBuilder<T>({
    required Future<T> future,
    required Widget Function(BuildContext, AsyncSnapshot<T>) builder,
    Widget? loadingWidget,
    Widget? errorWidget,
  }) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return errorWidget ?? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        return builder(context, snapshot);
      },
    );
  }

  // Optimized stream builder
  static Widget buildOptimizedStreamBuilder<T>({
    required Stream<T> stream,
    required Widget Function(BuildContext, AsyncSnapshot<T>) builder,
    T? initialData,
    Widget? loadingWidget,
    Widget? errorWidget,
  }) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && initialData == null) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return errorWidget ?? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        return builder(context, snapshot);
      },
    );
  }
}

 