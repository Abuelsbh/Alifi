# إضافة نظام المناطق للإعلانات

## الوظيفة
تمت إضافة إمكانية اختيار المناطق عند إضافة أو تعديل الإعلانات. يمكن للأدمن اختيار:
- **جميع المناطق** (All Locations) - يظهر الإعلان لجميع المستخدمين
- **منطقة واحدة أو عدة مناطق** - يظهر الإعلان فقط للمستخدمين في المناطق المحددة

## التغييرات المطبقة

### 1. ✅ تحديث نموذج الإعلان في Flutter
- إضافة حقل `locations` في `Advertisement` class
- الحقل عبارة عن `List<String>?` يحتوي على IDs المناطق
- إذا كان `null` أو فارغ أو يحتوي على `'all'`، يظهر الإعلان لجميع المستخدمين

### 2. ✅ تحديث خدمة الإعلانات
- تحديث `getActiveAdvertisements()` للتصفية حسب موقع المستخدم
- تحديث `getActiveAdvertisementsStream()` للتصفية حسب موقع المستخدم
- استخدام `LocationService.shouldShowForLocation()` للتحقق من صلاحية الإعلان

### 3. ✅ تحديث الداشبورد
- إضافة واجهة اختيار المناطق في نموذج الإعلان
- تحميل المناطق تلقائياً عند فتح النموذج
- إمكانية اختيار "All Locations" أو مناطق محددة
- عند اختيار "All Locations"، يتم تعطيل باقي الخيارات

### 4. ✅ تحديث Firebase
- تحديث `createAd()` لإضافة حقل `locations`
- تحديث `updateAd()` لتحديث حقل `locations`
- القيمة الافتراضية: `['all']` إذا لم يتم تحديد مناطق

## كيفية الاستخدام

### في الداشبورد:
1. افتح صفحة **Advertisements**
2. اضغط على **Add Advertisement**
3. املأ بيانات الإعلان
4. في قسم **Locations**:
   - اختر **All Locations** لعرض الإعلان لجميع المستخدمين
   - أو قم بإلغاء اختيار "All Locations" واختر مناطق محددة
5. احفظ الإعلان

### في التطبيق:
- الإعلانات تُصفّى تلقائياً حسب موقع المستخدم المختار
- الإعلانات التي لها `locations = ['all']` تظهر لجميع المستخدمين
- الإعلانات التي لها مناطق محددة تظهر فقط للمستخدمين في تلك المناطق

## ملاحظات مهمة

1. **التوافق مع البيانات القديمة**: الإعلانات القديمة التي لا تحتوي على `locations` ستعامل كـ "جميع المناطق"
2. **القيمة الافتراضية**: عند عدم تحديد مناطق، يتم تعيين `['all']` تلقائياً
3. **الفلترة**: يتم التصفية في التطبيق بعد جلب البيانات من Firebase

## الكود المهم

### في Flutter:
```dart
// Advertisement model
final List<String>? locations; // List of location IDs

// Filtering in service
.where((ad) {
  return LocationService.shouldShowForLocation(ad.locations, userLocationId);
})
```

### في الداشبورد:
```javascript
// Load locations
await this.loadAdLocations();

// Get selected locations
const allLocationsChecked = document.getElementById('ad-location-all').checked;
const locations = allLocationsChecked ? ['all'] : [...selectedLocationIds];
```

## الخطوات القادمة (اختياري)

- [ ] إضافة عرض المناطق المختارة في قائمة الإعلانات في الداشبورد
- [ ] إضافة إحصائيات حسب المناطق
- [ ] إضافة فلترة الإعلانات حسب المناطق في الداشبورد





