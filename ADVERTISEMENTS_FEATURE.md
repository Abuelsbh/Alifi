# خاصية الإعلانات - Advertisements Feature

## نظرة عامة
تم إضافة خاصية الإعلانات إلى تطبيق Alifi التي تسمح للمشرفين بإضافة حتى 10 إعلانات تظهر في التطبيق على الصفحة الرئيسية فوق الخدمات المتاحة.

## المكونات المضافة

### 1. Firebase Backend
- **Collection**: `advertisements`
- **Fields**:
  - `title` (string, optional): عنوان الإعلان
  - `description` (string, optional): وصف الإعلان
  - `imageUrl` (string, required): رابط صورة الإعلان
  - `displayOrder` (number): ترتيب العرض (1-10)
  - `isActive` (boolean): حالة نشاط الإعلان
  - `clickUrl` (string, optional): رابط التوجيه عند النقر
  - `views` (number): عدد مرات المشاهدة
  - `clickCount` (number): عدد مرات النقر
  - `createdAt` (timestamp): تاريخ الإنشاء
  - `updatedAt` (timestamp): تاريخ آخر تحديث

### 2. Web Admin Dashboard
#### صفحة إدارة الإعلانات
- **Navigation**: إضافة رابط "Advertisements" في الشريط الجانبي
- **Functions**:
  - عرض جميع الإعلانات
  - إضافة إعلان جديد
  - تعديل إعلان موجود
  - حذف إعلان
  - تفعيل/إلغاء تفعيل إعلان
  - معاينة الإعلان

#### إرشادات الإعلانات
- حد أقصى 10 إعلانات
- الصور يُفضل أن تكون بجودة عالية (1200x600px)
- استخدام ترتيب العرض للتحكم في الموضع
- الإعلانات غير المفعلة لن تظهر في التطبيق

### 3. Flutter Mobile App
#### خدمة الإعلانات
- **File**: `lib/core/services/advertisement_service.dart`
- **Functions**:
  - جلب الإعلانات النشطة
  - تسجيل مشاهدة الإعلان
  - تسجيل نقر الإعلان

#### واجهة المستخدم
- **File**: `lib/Widgets/advertisement_widget.dart`
- **Components**:
  - `AdvertisementCarousel`: عرض دائري للإعلانات
  - `AdvertisementCard`: بطاقة إعلان واحدة

#### التكامل مع الصفحة الرئيسية
- عرض الإعلانات فوق قسم "الخدمات المتاحة"
- تشغيل تلقائي للعرض الدائري
- مؤشرات للتنقل بين الإعلانات

## قواعد الأمان

### Firestore Security Rules
```javascript
// Advertisements collection
match /advertisements/{document} {
  // Anyone can read active advertisements
  allow read: if true;
  // Only admin users can write/modify advertisements
  allow write: if request.auth != null && request.auth.token.admin == true;
}
```

### Firebase Indexes
```json
{
  "collectionGroup": "advertisements",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "isActive",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "displayOrder",
      "order": "ASCENDING"
    }
  ]
}
```

## كيفية الاستخدام

### للمشرفين (Web Dashboard)
1. تسجيل الدخول إلى لوحة الإدارة
2. الانتقال إلى قسم "Advertisements"
3. النقر على "Add Advertisement"
4. ملء البيانات المطلوبة:
   - رابط الصورة (مطلوب)
   - العنوان (اختياري)
   - الوصف (اختياري)
   - ترتيب العرض (1-10)
   - رابط التوجيه (اختياري)
   - حالة النشاط
5. حفظ الإعلان

### للمستخدمين (Mobile App)
- الإعلانات تظهر تلقائياً في الصفحة الرئيسية
- يمكن التنقل بين الإعلانات بالسحب
- النقر على الإعلان يفتح الرابط المحدد (إن وُجد)

## الحزم المضافة
- `carousel_slider: ^4.2.1`: للعرض الدائري
- `cached_network_image: ^3.3.0`: لتحميل الصور بكفاءة
- `url_launcher: ^6.2.5`: لفتح الروابط

## ملاحظات تقنية
- الإعلانات تُحمل عند فتح الصفحة الرئيسية
- يتم تسجيل المشاهدات تلقائياً
- يتم تسجيل النقرات عند الضغط على الإعلان
- الإعلانات مُحسنة للأداء باستخدام التخزين المؤقت

## استكشاف الأخطاء
- التأكد من وجود رابط صورة صحيح
- التأكد من تفعيل الإعلان
- التحقق من صلاحيات Firebase
- مراجعة قواعد الأمان في Firestore

## التطوير المستقبلي
- إضافة رفع الصور مباشرة
- إضافة جدولة الإعلانات
- إضافة استهداف جغرافي
- إضافة تحليلات مفصلة
