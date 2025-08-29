import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/Theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  final String userName;
  final bool showAvatar;
  
  const TypingIndicator({
    super.key,
    required this.userName,
    this.showAvatar = true,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: 0,
        right: 60.w,
        bottom: 8.h,
      ),
      child: Row(
        children: [
          if (widget.showAvatar) ...[
            CircleAvatar(
              radius: 12.r,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 12.sp,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(width: 8.w),
          ],
          
          // Typing bubble
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
                bottomLeft: Radius.circular(4.r),
                bottomRight: Radius.circular(20.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.userName} يكتب',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(width: 8.w),
                _buildTypingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            double delay = index * 0.2;
            double animationValue = (_animation.value - delay).clamp(0.0, 1.0);
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              child: Transform.scale(
                scale: 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2).clamp(0.0, 1.0)),
                child: Container(
                  width: 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(
                      0.3 + (0.7 * (1 - (animationValue - 0.5).abs() * 2).clamp(0.0, 1.0)),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class LiveTypingIndicator extends StatelessWidget {
  final List<String> typingUsers;
  
  const LiveTypingIndicator({
    super.key,
    required this.typingUsers,
  });

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }
    
    String typingText = _getTypingText();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Icon(
            Icons.edit,
            size: 14.sp,
            color: AppTheme.primaryGreen,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              typingText,
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          _buildAnimatedDots(),
        ],
      ),
    );
  }

  String _getTypingText() {
    if (typingUsers.length == 1) {
      return '${typingUsers.first} يكتب';
    } else if (typingUsers.length == 2) {
      return '${typingUsers.join(' و ')} يكتبان';
    } else {
      return '${typingUsers.length} أشخاص يكتبون';
    }
  }

  Widget _buildAnimatedDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 500 + (index * 200)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              child: Opacity(
                opacity: (0.3 + (0.7 * value)).clamp(0.0, 1.0),
                child: Container(
                  width: 4.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
} 