import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Utilities/dialog_helper.dart';
import '../../../Widgets/login_widget.dart';
import '../../../Widgets/translated_text.dart';
import '../../../core/services/auth_service.dart';
import '../../add_animal/add_animal_flow.dart';
import '../../add_animal/add_animal_screen.dart';
import 'unified_lost_found_list.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  Widget _buildCustomFloatingActionButton() {
    return GestureDetector(
      onTap: () => _navigateToPostReport(context),
      child: SizedBox(
        width: 70.w,
        height: 70.h,
        child: Container(
          width: 56.w,
          height: 56.h,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 30.sp,
              weight: 700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.primaryGreen,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TranslatedText(
          'lost_found.title',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () => _navigateToPostReport(context),
            icon: Icon(
              Icons.add,
              color: AppTheme.primaryGreen,
              size: 24.sp,
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCustomFloatingActionButton(),
      body: const UnifiedLostFoundList(),
    );
  }

  void _navigateToPostReport(BuildContext context) {
    if (AuthService.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddAnimalScreen(
            flow: AddAnimalFlow.lostOrFound,
          ),
        ),
      );
    } else {
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: const LoginWidget(),
      );
    }
  }
}
