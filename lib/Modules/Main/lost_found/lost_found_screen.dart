import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/translated_text.dart';
import 'lost_pets_tab.dart';
import 'found_pets_tab.dart';
import 'post_report_screen.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCustomFloatingActionButton() {
    return GestureDetector(
      onTap: () => _navigateToPostReport(context),
      child: SizedBox(
        width: 70.w,
        height: 70.h,
        child:  Container(
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(child: TranslatedText('lost_found.lost_pets')),
            Tab(child: TranslatedText('lost_found.found_pets')),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _navigateToPostReport(context);
            },
            icon: Icon(
              Icons.add,
              color: AppTheme.primaryGreen,
              size: 24.sp,
            ),
          ),
        ],
      ),
      
      floatingActionButton: _buildCustomFloatingActionButton(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LostPetsTab(),
          FoundPetsTab(),
        ],
      ),
    );
  }

  void _navigateToPostReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostReportScreen(),
      ),
    );
  }
} 