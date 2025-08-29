import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rush/rush.dart';
import 'package:provider/provider.dart';

import 'Utilities/fast_http_config.dart';
import 'Utilities/git_it.dart';
import 'Utilities/router_config.dart';
import 'core/Font/font_provider.dart';
import 'core/Language/app_languages.dart';
import 'core/Language/locales.dart';
import 'core/Theme/theme_provider.dart';
import 'core/firebase/firebase_config.dart';
import 'core/Theme/app_theme.dart';
import 'core/services/data_seeding_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseConfig.initialize();

  RushSetup.init(
    largeScreens: RushScreenSize.large,
    mediumScreens: RushScreenSize.medium,
    smallScreens: RushScreenSize.small,
    startMediumSize: 768,
    startLargeSize: 1200,
  );

  FastHttpConfig.init();

  await GitIt.initGitIt();

  // Initialize demo data if Firebase is available
  if (!FirebaseConfig.isDemoMode) {
    try {
      await DataSeedingService.initializeAllDemoData();
    } catch (e) {
      print('Could not initialize demo data: $e');
    }
  }
  
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppLanguage>(create: (_) => AppLanguage()),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<FontProvider>(create: (_) => FontProvider()),
        ],
      child: const AlifiApp(),
      )
  );
}

class AlifiApp extends StatelessWidget {
  const AlifiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appLan = Provider.of<AppLanguage>(context);
    final appTheme = Provider.of<ThemeProvider>(context);
    appLan.fetchLocale();
    appTheme.fetchTheme();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScreenUtilInit(
          designSize: RushSetup.getSize(
            maxWidth: constraints.maxWidth,
            largeSize: const Size(1920, 1080),
            mediumSize: const Size(1000, 780),
            smallSize: const Size(375, 812),
          ),
          builder: (_, __) => MaterialApp.router(
            scrollBehavior: MyCustomScrollBehavior(),
            routerConfig: GoRouterConfig.router,
            debugShowCheckedModeBanner: false,
            title: 'Alifi - Pet Care Platform',
            locale: Locale(appLan.appLang.name),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appTheme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            supportedLocales: Languages.values.map((e) => Locale(e.name)).toList(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
              DefaultMaterialLocalizations.delegate
            ],
          ),
        );
      },
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
