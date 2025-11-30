import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../Models/chat_model.dart';
import '../../../Widgets/message_bubble.dart';
import '../../../generated/assets.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../Widgets/custom_textfield_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'unified_pet_details_screen.dart';

class UserChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final bool? isVeterinaryChat; // null means auto-detect

  const UserChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.isVeterinaryChat,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isSending = false;
  bool _showAttachmentMenu = false;
  List<ChatMessage> _messages = [];
  ChatModel? _chatModel;
  Map<String, dynamic>? _petReportInfo;
  bool _isVeterinaryChat = false;
  
  late AnimationController _attachmentAnimationController;
  late Animation<double> _attachmentAnimation;
  
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Set initial chat type if provided
    if (widget.isVeterinaryChat != null) {
      _isVeterinaryChat = widget.isVeterinaryChat!;
    }
    _loadMessages(); // _loadMessages will call _loadChatInfo first
  }

  Future<void> _loadChatInfo() async {
    try {
      // Auto-detect chat type if not specified
      if (widget.isVeterinaryChat == null) {
        // Try veterinary_chats first
        final vetChatDoc = await FirebaseFirestore.instance
            .collection('veterinary_chats')
            .doc(widget.chatId)
            .get();
        
        if (vetChatDoc.exists) {
          setState(() {
            _isVeterinaryChat = true;
            _chatModel = ChatModel.fromFirestore(vetChatDoc);
          });
        } else {
          // Try user_chats
          final userChatDoc = await FirebaseFirestore.instance
              .collection('user_chats')
              .doc(widget.chatId)
              .get();
          
          if (userChatDoc.exists) {
            setState(() {
              _isVeterinaryChat = false;
              _chatModel = ChatModel.fromFirestore(userChatDoc);
            });
          }
        }
      } else {
        // Use specified chat type
        _isVeterinaryChat = widget.isVeterinaryChat!;
        final collectionName = _isVeterinaryChat ? 'veterinary_chats' : 'user_chats';
        final chatDoc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(widget.chatId)
            .get();
        
        if (chatDoc.exists) {
          setState(() {
            _chatModel = ChatModel.fromFirestore(chatDoc);
          });
        }
      }
      
      // Load pet report info if exists
      if (_chatModel?.petReportId != null && _chatModel?.petReportType != null) {
        await _loadPetReportInfo(_chatModel!.petReportId!, _chatModel!.petReportType!);
      }
    } catch (e) {
      print('Error loading chat info: $e');
    }
  }

  Future<void> _loadPetReportInfo(String reportId, String reportType) async {
    try {
      DocumentSnapshot? reportDoc;
      String collectionName = '';
      
      switch (reportType) {
        case 'lost':
          collectionName = 'lost_pets';
          break;
        case 'found':
          collectionName = 'found_pets';
          break;
        case 'adoption':
          collectionName = 'adoption_pets';
          break;
        case 'breeding':
          collectionName = 'breeding_pets';
          break;
        default:
          return;
      }
      
      reportDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(reportId)
          .get();
      
      if (reportDoc.exists && mounted) {
        final data = reportDoc.data() as Map<String, dynamic>;
        setState(() {
          _petReportInfo = {
            'id': reportId,
            'type': reportType,
            'petName': data['petName'] ?? 
                      data['petDetails']?['name'] ?? 
                      'حيوان',
            'imageUrl': (data['imageUrls'] as List?)?.isNotEmpty == true 
                ? data['imageUrls'][0] 
                : (data['photos'] as List?)?.isNotEmpty == true 
                    ? data['photos'][0] 
                    : null,
            ...data,
          };
        });
      }
    } catch (e) {
      print('Error loading pet report info: $e');
    }
  }

  void _initializeAnimations() {
    _attachmentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _attachmentAnimation = CurvedAnimation(
      parent: _attachmentAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _attachmentAnimationController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    // Wait for chat info to be loaded first to determine chat type
    await _loadChatInfo();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = AuthService.userId;
      if (userId != null) {
        if (_isVeterinaryChat) {
          await ChatService.markMessagesAsRead(
            chatId: widget.chatId,
            userId: userId,
          );
        } else {
          await ChatService.markUserMessagesAsRead(
            chatId: widget.chatId,
            userId: userId,
          );
        }
      }
      
      // Use appropriate stream based on chat type
      final messagesStream = _isVeterinaryChat
          ? ChatService.getChatMessagesStream(widget.chatId)
          : ChatService.getUserChatMessagesStream(widget.chatId);
      
      _messagesSubscription = messagesStream.listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('خطأ في تحميل الرسائل: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    final userId = AuthService.userId;
    
    if (userId == null) {
      _showErrorSnackBar('خطأ في المصادقة');
      return;
    }

    _messageController.clear();
    setState(() {
      _isSending = true;
    });

    try {
      if (_isVeterinaryChat) {
        await ChatService.sendTextMessage(
          chatId: widget.chatId,
          senderId: userId,
          message: message,
        );
      } else {
        await ChatService.sendUserTextMessage(
          chatId: widget.chatId,
          senderId: userId,
          message: message,
        );
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال الرسالة: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendImageMessage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        await _uploadAndSendImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    final userId = AuthService.userId;
    if (userId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      if (_isVeterinaryChat) {
        await ChatService.sendImageMessage(
          chatId: widget.chatId,
          senderId: userId,
          imageFile: imageFile,
        );
      } else {
        await ChatService.sendUserImageMessage(
          chatId: widget.chatId,
          senderId: userId,
          imageFile: imageFile,
        );
      }
      
      _hideAttachmentMenu();
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      _showErrorSnackBar('خطأ في رفع الصورة: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
    });
    
    if (_showAttachmentMenu) {
      _attachmentAnimationController.forward();
    } else {
      _attachmentAnimationController.reverse();
    }
  }

  void _hideAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = false;
    });
    _attachmentAnimationController.reverse();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GestureDetector(
        onTap: _hideAttachmentMenu,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(Assets.imagesBackground3),
              fit: BoxFit.contain,
            ),
          ),
          child: Column(
            children: [
              Gap(45.h),
              Row(
                children: [_buildAppBar()],
              ),
              if (_petReportInfo != null) _buildPetReportBanner(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingIndicator()
                    : _buildMessagesList(),
              ),
              _buildAttachmentMenu(),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 200.w,
          height: 73.h,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: ThemeClass.of(context).secondaryColor,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.otherUserName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: ThemeClass.of(context).backGroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -10.h,
          left: 0,
          right: 0,
          child: Center(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.otherUserId)
                  .get(),
              builder: (context, snapshot) {
                String? profilePhoto;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  profilePhoto = data?['profileImageUrl'] ?? data?['profilePhoto'];
                }
                
                return CircleAvatar(
                  radius: 25.r,
                  backgroundColor: ThemeClass.of(context).primaryColor,
                  backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                      ? NetworkImage(profilePhoto)
                      : null,
                  child: profilePhoto == null || profilePhoto.isEmpty
                      ? Icon(
                          Icons.person,
                          color: ThemeClass.of(context).secondaryColor,
                          size: 35.sp,
                        )
                      : null,
                );
              },
            ),
          ),
        ),
      ],
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
            'جاري تحميل الرسائل...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetReportBanner() {
    if (_petReportInfo == null) return const SizedBox.shrink();
    
    final petName = _petReportInfo!['petName'] ?? 'حيوان';
    final imageUrl = _petReportInfo!['imageUrl'] as String?;
    final reportType = _petReportInfo!['type'] ?? 'report';
    final reportId = _petReportInfo!['id'] as String?;
    
    String typeLabel = 'إعلان';
    Color typeColor = AppTheme.primaryGreen;
    IconData typeIcon = Icons.pets;
    
    if (reportType == 'lost') {
      typeLabel = 'مفقود';
      typeColor = AppTheme.error;
      typeIcon = Icons.search;
    } else if (reportType == 'found') {
      typeLabel = 'موجود';
      typeColor = AppTheme.success;
      typeIcon = Icons.check_circle;
    } else if (reportType == 'adoption') {
      typeLabel = 'تبني';
      typeColor = AppTheme.primaryGreen;
      typeIcon = Icons.favorite;
    } else if (reportType == 'breeding') {
      typeLabel = 'تزاوج';
      typeColor = AppTheme.primaryOrange;
      typeIcon = Icons.family_restroom;
    }
    
    return GestureDetector(
      onTap: () {
        if (reportId != null) {
          _navigateToPetDetails(reportType, reportId);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: typeColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 50.w,
                  height: 50.h,
                  fit: BoxFit.cover,
                  memCacheWidth: 100,
                  memCacheHeight: 100,
                  placeholder: (context, url) => Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: typeColor,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 24.sp),
                    );
                  },
                ),
              )
            else
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24.sp),
              ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'محادثة حول: $petName',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'اضغط لعرض الإعلان',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: typeColor,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPetDetails(String reportType, String reportId) async {
    try {
      DocumentSnapshot? reportDoc;
      String collectionName = '';
      PetDetailsType? detailsType;
      
      switch (reportType) {
        case 'lost':
          collectionName = 'lost_pets';
          detailsType = PetDetailsType.report;
          break;
        case 'found':
          collectionName = 'found_pets';
          detailsType = PetDetailsType.report;
          break;
        case 'adoption':
          collectionName = 'adoption_pets';
          detailsType = PetDetailsType.adoption;
          break;
        case 'breeding':
          collectionName = 'breeding_pets';
          detailsType = PetDetailsType.breeding;
          break;
        default:
          return;
      }
      
      reportDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(reportId)
          .get();
      
      if (!reportDoc.exists || detailsType == null) {
        return;
      }
      
      final finalDetailsType = detailsType;
      
      final data = reportDoc.data() as Map<String, dynamic>;
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            if (finalDetailsType == PetDetailsType.report) {
              return UnifiedPetDetailsScreen(
                type: finalDetailsType,
                report: {'id': reportId, ...data},
              );
            } else if (finalDetailsType == PetDetailsType.adoption) {
              return UnifiedPetDetailsScreen(
                type: finalDetailsType,
                report: {'id': reportId, ...data},
              );
            } else {
              return UnifiedPetDetailsScreen(
                type: finalDetailsType,
                report: {'id': reportId, ...data},
              );
            }
          },
        ),
      );
    } catch (e) {
      print('Error navigating to pet details: $e');
    }
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: EdgeInsets.all(16.w),
      itemCount: _getMessageListItems().length,
      itemBuilder: (context, index) {
        final item = _getMessageListItems()[index];
        if (item is String) {
          // Date separator
          return _buildDateSeparator(item);
        } else {
          // Message
          final message = item as ChatMessage;
          return MessageBubble(
            message: message,
            isMe: message.senderId == AuthService.userId,
            onTap: () {},
            onLongPress: () {},
          );
        }
      },
    );
  }

  List<dynamic> _getMessageListItems() {
    final items = <dynamic>[];
    DateTime? currentDate;
    
    for (var message in _messages) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      
      // Add date separator if it's a new day
      if (currentDate == null || !_isSameDay(currentDate, messageDate)) {
        items.add(_formatDateSeparator(messageDate));
        currentDate = messageDate;
      }
      
      items.add(message);
    }
    
    return items;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (_isSameDay(messageDate, today)) {
      return 'اليوم';
    } else if (_isSameDay(messageDate, yesterday)) {
      return 'أمس';
    } else {
      // Format: "15 نوفمبر" or "15/11"
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${date.day} ${months[date.month - 1]}';
    }
  }

  Widget _buildDateSeparator(String dateText) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                dateText,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey[300],
              thickness: 1,
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
          Icon(
            Icons.chat_bubble_outline,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'ابدأ محادثة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'ارسل رسالة لبدء المحادثة',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    return AnimatedBuilder(
      animation: _attachmentAnimation,
      builder: (context, child) {
        return Container(
          height: _attachmentAnimation.value * 120.h,
          child: _attachmentAnimation.value > 0
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAttachmentButton(
                        icon: Icons.camera_alt,
                        label: 'كاميرا',
                        color: AppTheme.primaryGreen,
                        onPressed: () => _sendImageMessage(ImageSource.camera),
                      ),
                      _buildAttachmentButton(
                        icon: Icons.photo_library,
                        label: 'معرض',
                        color: AppTheme.primaryOrange,
                        onPressed: () => _sendImageMessage(ImageSource.gallery),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8.w),
      child: Row(
        children: [
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: ThemeClass.of(context).lightGreyColor,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Row(
              children: [
                CustomTextFieldWidget(
                  width: 238.w,
                  height: 42.h,
                  controller: _messageController,
                  borderStyleFlag: 4,
                  hint: 'اكتب رسالة...',
                  onSave: (_) => _sendTextMessage(),
                ),
                GestureDetector(
                  onTap: _toggleAttachmentMenu,
                  child: Padding(
                    padding: EdgeInsets.all(_showAttachmentMenu ? 6.0 : 4.0),
                    child: SvgPicture.asset(
                      _showAttachmentMenu ? Assets.iconsCancel : Assets.iconsAttachment,
                      color: _showAttachmentMenu
                          ? ThemeClass.of(context).darkGreyColor
                          : ThemeClass.of(context).secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _isSending ? null : _sendTextMessage,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _isSending
                    ? Colors.grey[400]
                    : AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color: ThemeClass.of(context).primaryColor,
                      size: 20.sp,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

