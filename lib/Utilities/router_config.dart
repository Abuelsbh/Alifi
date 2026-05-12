import 'package:alifi/Modules/Main/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Modules/Splash/splash_screen.dart';
import '../Modules/Main/lost_found/lost_found_screen.dart';
import '../Modules/Main/veterinary/enhanced_veterinary_screen.dart';
import '../Modules/Main/profile/simple_profile_screen.dart';
import '../Modules/Main/stores/pet_stores_screen.dart';
import '../Modules/Auth/login_screen.dart';
import '../Modules/Auth/register_screen.dart';
import '../Modules/Auth/demo_mode_screen.dart';
import '../Modules/Auth/simple_register_test.dart';
import '../Modules/Admin/admin_dashboard_screen.dart';
import '../Modules/add_animal/add_animal_flow.dart';
import '../Modules/add_animal/add_animal_screen.dart';
import '../Modules/Main/location/location_selection_screen.dart';

BuildContext? get currentContext_ =>
    GoRouterConfig.router.routerDelegate.navigatorKey.currentContext;

class GoRouterConfig{
  static GoRouter get router => _router;
  static final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: SplashScreen.routeName,
        name: 'splash',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const SplashScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: LocationSelectionScreen.routeName,
        name: 'locationSelection',
        pageBuilder: (_, GoRouterState state) {
          final isFirstTime = state.queryParameters['firstTime'] == 'true';
          return getCustomTransitionPage(
            state: state,
            child: LocationSelectionScreen(isFirstTime: isFirstTime),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: DemoModeScreen.routeName,
        name: 'demo',
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
        name: 'login',
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
        name: 'register',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const RegisterScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: HomeScreen.routeName,
        name: 'home',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const HomeScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: '/LostFoundScreen',
        name: 'lostFound',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const LostFoundScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: '/PostReportScreen',
        name: 'postReport',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const AddAnimalScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: '/AddAnimal',
        name: 'addAnimal',
        pageBuilder: (_, GoRouterState state) {
          final extra = state.extra;
          final flow = extra is AddAnimalFlow ? extra : null;
          return getCustomTransitionPage(
            state: state,
            child: AddAnimalScreen(flow: flow),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: '/VeterinaryScreen',
        name: 'veterinary',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const EnhancedVeterinaryScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: '/ProfileScreen',
        name: 'profile',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const SimpleProfileScreen(),
          );
        },
        routes: const <RouteBase>[],
      ),
      GoRoute(
        path: '/test-register',
        name: 'testRegister',
        pageBuilder: (_, GoRouterState state) {
          return getCustomTransitionPage(
            state: state,
            child: const SimpleRegisterTest(),
          );
        },
        routes: const <RouteBase>[],
      ),
                    GoRoute(
                path: PetStoresScreen.routeName,
                name: 'pet-stores',
                pageBuilder: (_, GoRouterState state) {
                  return getCustomTransitionPage(
                    state: state,
                    child: const PetStoresScreen(),
                  );
                },
                routes: const <RouteBase>[],
              ),
              GoRoute(
                path: AdminDashboardScreen.routeName,
                name: 'admin',
                pageBuilder: (_, GoRouterState state) {
                  return getCustomTransitionPage(
                    state: state,
                    child: const AdminDashboardScreen(),
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

  static MaterialPage getCustomTransitionPage({required GoRouterState state, required Widget child}){
    return MaterialPage(
      key: state.pageKey,
      child: child,
    );
  }
}




