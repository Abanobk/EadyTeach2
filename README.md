# Easy Tech Flutter App

تطبيق Flutter كامل لإدارة المنزل الذكي - يدعم Android وiOS والويب.

## هيكل التطبيق

```
lib/
├── main.dart                    # نقطة الدخول + SplashScreen
├── providers/
│   ├── auth_provider.dart       # إدارة المصادقة والجلسة
│   └── cart_provider.dart       # إدارة سلة التسوق
├── services/
│   └── api_service.dart         # الاتصال بـ tRPC API
├── utils/
│   └── app_theme.dart           # الثيم والألوان
└── screens/
    ├── auth/
    │   ├── login_screen.dart
    │   └── role_select_screen.dart
    ├── client/
    │   ├── client_home_screen.dart
    │   ├── product_detail_screen.dart
    │   ├── cart_screen.dart
    │   ├── orders_screen.dart
    │   └── profile_screen.dart
    ├── technician/
    │   ├── technician_home_screen.dart
    │   └── task_detail_screen.dart
    └── admin/
        ├── admin_home_screen.dart
        ├── admin_orders_screen.dart
        ├── admin_customers_screen.dart
        ├── admin_products_screen.dart
        └── admin_tasks_screen.dart
```

## الأدوار المدعومة

- عميل: المتجر، السلة، الطلبات، بياناتي
- فني: قائمة المهام، تفاصيل المهمة، تحديث الحالة
- أدمن: لوحة التحكم، الطلبات، العملاء، المنتجات، المهام

## الإعداد والتشغيل

```bash
# تثبيت الاعتماديات
flutter pub get

# تشغيل على Android
flutter run

# بناء APK للإصدار
flutter build apk --release

# بناء APK للاختبار
flutter build apk --debug

# بناء للويب
flutter build web
```

## الاتصال بالـ API

التطبيق يتصل بـ: https://easytechapp-n8wz4sb5.manus.space

لتغيير الرابط، عدّل: lib/services/api_service.dart
السطر: static const String baseUrl = '...';

## النشر على Google Play

```bash
# بناء App Bundle (موصى به)
flutter build appbundle --release
# الملف: build/app/outputs/bundle/release/app-release.aab

# أو APK
flutter build apk --release
# الملف: build/app/outputs/flutter-apk/app-release.apk
```

## الميزات

- دعم RTL (عربي كامل)
- ثيم داكن احترافي
- ثلاثة أدوار في تطبيق واحد
- يدعم Android وiOS والويب
- حفظ السلة محلياً
- إدارة الجلسة عبر cookies
