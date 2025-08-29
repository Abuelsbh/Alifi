import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Modules/Splash/splash_screen.dart';
import '../Modules/Main/main_screen.dart';
import '../Modules/Auth/login_screen.dart';
import '../Modules/Auth/register_screen.dart';
import '../Modules/Auth/demo_mode_screen.dart';
import '../Modules/Auth/simple_register_test.dart';

BuildContext? get currentContext_ =>
    GoRouterConfig.router.routerDelegate.navigatorKey.currentContext;

class GoRouterConfig{
  static GoRouter get router => _router;
  static final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: SplashScreen.routeName,
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const SplashScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: DemoModeScreen.routeName,
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const DemoModeScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: LoginScreen.routeName,
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const LoginScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: RegisterScreen.routeName,
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const RegisterScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: MainScreen.routeName,
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const MainScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: '/test-register',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const SimpleRegisterTest(),
          );
        },
        routes: const <RouteBase>[],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // TODO: Add authentication logic
      // if(!SharedPref.isLogin()) return LoginScreen.routeName;
      // if(state.matchedLocation == LoginScreen.routeName && SharedPref.isLogin()) return "/${HomeScreen.routeName}";
      return null;
    },
  );

  static CustomTransitionPage getCustomTransitionPage({required GoRouterState state, required Widget child}){
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
          child: child,
        );
      },
    );
  }
}





