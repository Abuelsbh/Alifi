import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';
import 'add_pet_screen.dart';
import 'pet_details_screen.dart';

class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _pets = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPets();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = AuthService.userId;
      if (userId != null) {
        // TODO: Load pets from Firestore
        await Future.delayed(const Duration(seconds: 1));
        
        // Mock data for now
        _pets = [
          {
            'id': '1',
            'name': 'بلاكي',
            'type': 'كلب',
            'breed': 'جولدن ريتريفر',
            'age': 3,
            'gender': 'ذكر',
            'color': 'ذهبي',
            'weight': 25.5,
            'imageUrl': null,
            'medicalHistory': [
              {
                'date': '2024-01-15',
                'type': 'تطعيم',
                'description': 'تطعيم سنوي ضد الكلب والقطط',
                'vetName': 'د. أحمد محمد',
              },
              {
                'date': '2024-02-20',
                'type': 'فحص',
                'description': 'فحص دوري شامل',
                'vetName': 'د. سارة أحمد',
              },
            ],
            'vaccinations': [
              {
                'name': 'Rabies',
                'date': '2024-01-15',
                'nextDue': '2025-01-15',
              },
              {
                'name': 'DHPP',
                'date': '2024-01-15',
                'nextDue': '2025-01-15',
              },
            ],
            'microchip': '123456789012345',
            'isNeutered': true,
            'allergies': ['الفول السوداني'],
            'medications': [],
            'emergencyContact': {
              'name': 'أحمد محمد',
              'phone': '+201234567890',
            },
            'createdAt': DateTime.now().subtract(const Duration(days: 90)),
          },
          {
            'id': '2',
            'name': 'مياو',
            'type': 'قطة',
            'breed': 'شيرازي',
            'age': 2,
            'gender': 'أنثى',
            'color': 'أبيض وبرتقالي',
            'weight': 4.2,
            'imageUrl': null,
            'medicalHistory': [
              {
                'date': '2024-03-10',
                'type': 'تطعيم',
                'description': 'تطعيم ضد الأمراض الفيروسية',
                'vetName': 'د. فاطمة علي',
              },
            ],
            'vaccinations': [
              {
                'name': 'FVRCP',
                'date': '2024-03-10',
                'nextDue': '2025-03-10',
              },
            ],
            'microchip': null,
            'isNeutered': true,
            'allergies': [],
            'medications': ['قطرات العين - مرتين يومياً'],
            'emergencyContact': {
              'name': 'أحمد محمد',
              'phone': '+201234567890',
            },
            'createdAt': DateTime.now().subtract(const Duration(days: 60)),
          },
        ];
      }
    } catch (e) {
      print('Error loading pets: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'حيواناتي الأليفة',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.primaryGreen),
            onPressed: _addNewPet,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? _buildLoadingIndicator()
            : _pets.isEmpty
                ? _buildEmptyState()
                : _buildPetsList(),
      ),
      floatingActionButton: _pets.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addNewPet,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل الحيوانات الأليفة...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              size: 60.sp,
              color: AppTheme.primaryGreen,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'لا توجد حيوانات أليفة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'أضف حيوانك الأليف الأول لتتمكن من\nمتابعة صحته وتاريخه الطبي',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          CustomButton(
            text: 'إضافة حيوان أليف',
            onPressed: _addNewPet,
            icon: Icons.add,
            backgroundColor: AppTheme.primaryGreen,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _pets.length,
      itemBuilder: (context, index) {
        final pet = _pets[index];
        return _buildPetCard(pet, index);
      },
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: 16.h),
      child: CustomCard(
        onTap: () => _viewPetDetails(pet),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Pet Avatar
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: pet['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30.r),
                        child: CachedNetworkImage(
                          imageUrl: pet['imageUrl'],
                          fit: BoxFit.cover,
                          memCacheWidth: 100,
                          memCacheHeight: 100,
                          maxWidthDiskCache: 300,
                          maxHeightDiskCache: 300,
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
                            return _buildPetIcon(pet['type']);
                          },
                        ),
                      )
                    : _buildPetIcon(pet['type']),
              ),
              
              SizedBox(width: 16.w),
              
              // Pet Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet['name'] ?? 'غير محدد',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: _getPetTypeColor(pet['type']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            pet['type'] ?? '',
                            style: TextStyle(
                              color: _getPetTypeColor(pet['type']),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${pet['breed'] ?? 'غير محدد'} • ${pet['gender'] ?? 'غير محدد'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.cake,
                          size: 14.sp,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${pet['age'] ?? 0} سنة',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Icon(
                          Icons.monitor_weight,
                          size: 14.sp,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${pet['weight'] ?? 0} كجم',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Next vaccination indicator
              if (_hasUpcomingVaccination(pet))
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    size: 16.sp,
                    color: AppTheme.warning,
                  ),
                ),
              
              SizedBox(width: 8.w),
              
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetIcon(String? petType) {
    IconData icon;
    switch (petType?.toLowerCase()) {
      case 'كلب':
      case 'dog':
        icon = Icons.pets;
        break;
      case 'قطة':
      case 'cat':
        icon = Icons.pets;
        break;
      case 'أرنب':
      case 'rabbit':
        icon = Icons.cruelty_free;
        break;
      case 'طائر':
      case 'bird':
        icon = Icons.flutter_dash;
        break;
      default:
        icon = Icons.pets;
    }
    
    return Icon(
      icon,
      size: 30.sp,
      color: AppTheme.primaryGreen,
    );
  }

  Color _getPetTypeColor(String? petType) {
    switch (petType?.toLowerCase()) {
      case 'كلب':
      case 'dog':
        return Colors.brown;
      case 'قطة':
      case 'cat':
        return Colors.orange;
      case 'أرنب':
      case 'rabbit':
        return Colors.pink;
      case 'طائر':
      case 'bird':
        return Colors.blue;
      default:
        return AppTheme.primaryGreen;
    }
  }

  bool _hasUpcomingVaccination(Map<String, dynamic> pet) {
    final vaccinations = pet['vaccinations'] as List<dynamic>? ?? [];
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    
    for (var vaccination in vaccinations) {
      final nextDueStr = vaccination['nextDue'] as String?;
      if (nextDueStr != null) {
        try {
          final nextDue = DateTime.parse(nextDueStr);
          if (nextDue.isBefore(thirtyDaysFromNow) && nextDue.isAfter(now)) {
            return true;
          }
        } catch (e) {
          // Invalid date format, skip
        }
      }
    }
    return false;
  }

  void _addNewPet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPetScreen(),
      ),
    ).then((_) {
      // Refresh pets list after adding new pet
      _loadPets();
    });
  }

  void _viewPetDetails(Map<String, dynamic> pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailsScreen(pet: pet),
      ),
    ).then((_) {
      // Refresh pets list in case of updates
      _loadPets();
    });
  }
} 