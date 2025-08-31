# نظام الأطباء البيطريين - Veterinary System

## نظرة عامة
تم إنشاء نظام كامل للأطباء البيطريين مع إمكانية تسجيل الدخول والحديث مع المستخدمين عبر Firebase Realtime Database.

## الميزات المضافة

### 1. خدمة الأطباء البيطريين (`VeterinaryService`)
- إنشاء حسابات الأطباء البيطريين
- تسجيل دخول الأطباء البيطريين
- إدارة حالة الاتصال (متصل/غير متصل)
- تحديث الملف الشخصي للطبيب
- جلب قائمة الأطباء البيطريين

### 2. شاشة تسجيل دخول الطبيب البيطري (`VeterinarianLoginScreen`)
- واجهة مخصصة لتسجيل دخول الأطباء البيطريين
- بيانات الدخول التجريبية: `doctor@gmail.com` / `000111`
- التحقق من صحة البيانات
- التنقل إلى لوحة تحكم الطبيب

### 3. لوحة تحكم الطبيب البيطري (`VeterinarianDashboardScreen`)
- عرض معلومات الطبيب البيطري
- قائمة المحادثات مع المستخدمين
- عرض عدد الرسائل غير المقروءة
- إمكانية تسجيل الخروج

### 4. تحديث خدمة المحادثات (`ChatService`)
- إزالة البيانات الوهمية
- استخدام Firebase Realtime Database
- إنشاء محادثات حقيقية مع الأطباء البيطريين
- إرسال واستقبال الرسائل في الوقت الفعلي

## كيفية الإعداد

### 1. إعداد Firebase
تأكد من أن Firebase مُعد بشكل صحيح في مشروعك مع:
- Firebase Authentication
- Cloud Firestore
- Realtime Database (اختياري للمحادثات)

### 2. إنشاء حساب الطبيب البيطري
قم بتشغيل السكريبت التالي لإنشاء حساب الطبيب البيطري:

```bash
dart scripts/create_veterinarian.dart
```

أو قم بإنشاء الحساب يدوياً في Firebase Console:

#### في Firebase Authentication:
- أنشئ مستخدم جديد
- Email: `doctor@gmail.com`
- Password: `000111`

#### في Cloud Firestore:
أنشئ مجموعة `veterinarians` مع المستند التالي:

```json
{
  "uid": "USER_ID_FROM_AUTH",
  "email": "doctor@gmail.com",
  "name": "د. أحمد محمد",
  "specialization": "الطب البيطري العام",
  "experience": "10 سنوات",
  "phone": "+201234567890",
  "profileImage": null,
  "bio": "طبيب بيطري متخصص في علاج الكلاب والقطط مع خبرة 10 سنوات في الطب البيطري",
  "isOnline": false,
  "rating": 4.8,
  "totalRatings": 124,
  "isVerified": true,
  "createdAt": "TIMESTAMP",
  "updatedAt": "TIMESTAMP",
  "userType": "veterinarian",
  "address": "القاهرة، مصر الجديدة",
  "workingHours": "السبت - الخميس: 9 صباحاً - 6 مساءً",
  "languages": ["العربية", "الإنجليزية"]
}
```

### 3. إعداد قواعد الأمان في Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // قواعد الأطباء البيطريين
    match /veterinarians/{vetId} {
      allow read: if true; // يمكن للجميع قراءة بيانات الأطباء
      allow write: if request.auth != null && request.auth.uid == vetId; // فقط الطبيب يمكنه تحديث بياناته
    }
    
    // قواعد المحادثات البيطرية
    match /veterinary_chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
    
    // قواعد الرسائل
    match /veterinary_chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/veterinary_chats/$(chatId)).data.participants;
    }
  }
}
```

## كيفية الاستخدام

### للمستخدمين العاديين:
1. انتقل إلى شاشة الاستشارات البيطرية
2. اختر طبيب بيطري من القائمة
3. اضغط على "بدء محادثة"
4. اكتب رسالتك الأولى
5. انتظر رد الطبيب

### للأطباء البيطريين:
1. اضغط على "هل أنت طبيب بيطري؟" في شاشة تسجيل الدخول
2. سجل الدخول باستخدام:
   - Email: `doctor@gmail.com`
   - Password: `000111`
3. ستظهر لك لوحة التحكم مع جميع المحادثات
4. اضغط على أي محادثة للرد على المستخدمين

## الملفات المضافة/المحدثة

### ملفات جديدة:
- `lib/core/services/veterinary_service.dart`
- `lib/Modules/Auth/veterinarian_login_screen.dart`
- `lib/Modules/Main/veterinary/veterinarian_dashboard_screen.dart`
- `scripts/create_veterinarian.dart`

### ملفات محدثة:
- `lib/core/services/chat_service.dart` - إزالة البيانات الوهمية
- `lib/Modules/Auth/login_screen.dart` - إضافة رابط تسجيل دخول الطبيب
- `i18n/en.json` و `i18n/ar.json` - إضافة الترجمات الجديدة

## ملاحظات مهمة

1. **لا توجد بيانات وهمية**: تم إزالة جميع البيانات الوهمية من النظام
2. **Firebase مطلوب**: يجب أن يكون Firebase مُعد بشكل صحيح
3. **الأمان**: تم تطبيق قواعد أمان مناسبة في Firestore
4. **الترجمة**: النظام يدعم العربية والإنجليزية بالكامل
5. **الأداء**: تم تحسين الأداء باستخدام Streams وCaching

## استكشاف الأخطاء

### إذا لم تظهر الأطباء البيطريين:
1. تأكد من أن Firebase مُعد بشكل صحيح
2. تحقق من وجود بيانات في مجموعة `veterinarians`
3. تأكد من أن `isVerified` = true

### إذا فشل تسجيل دخول الطبيب:
1. تأكد من وجود الحساب في Firebase Authentication
2. تحقق من وجود الملف الشخصي في Firestore
3. تأكد من صحة كلمة المرور

### إذا لم تعمل المحادثات:
1. تحقق من قواعد الأمان في Firestore
2. تأكد من أن المستخدم مسجل دخول
3. تحقق من اتصال الإنترنت 