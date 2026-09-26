import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/communication/communication_screen.dart';
import '../screens/connection/connection_screen.dart';
import '../screens/emergency/emergency_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/secondary/about/about_screen.dart';
import '../screens/secondary/ai_info/ai_info_screen.dart';
import '../screens/secondary/diagnostics/diagnostics_screen.dart';
import '../screens/secondary/languages/language_screen.dart';
import '../screens/setup/setup_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../widgets/bottom_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

/// GoRouter configuration with 4 primary bottom navigation tabs,
/// 7 core screens, and secondary system pages.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // 1. Core Screen: Splash
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // 2. Core Screen: Setup
    GoRoute(
      path: '/setup',
      builder: (context, state) => const SetupScreen(),
    ),

    // Stateful Shell with exactly 4 bottom navigation tabs:
    // Tab 0: Home (Core Screen 2)
    // Tab 1: History (Core Screen 5)
    // Tab 2: Emergency (Core Screen 6)
    // Tab 3: Settings (Core Screen 7)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Tab 1: History
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),

        // Tab 2: Emergency (Dynamic states: Idle, Confirming, Sending, Sent, Received)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/emergency',
              builder: (context, state) => const EmergencyScreen(),
            ),
          ],
        ),

        // Tab 3: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // 3. Core Screen: Connect Device
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/connect',
      builder: (context, state) => const ConnectionScreen(),
    ),

    // 4. Core Screen: Communication Transceiver (Dynamic states: Idle, Listening, Processing, Ready, Sending, Sent, Receiving)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/communication',
      builder: (context, state) => const CommunicationScreen(),
    ),

    // Secondary Pages (accessible from Settings and relevant actions)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/languages',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/ai-info',
      builder: (context, state) => const AiInfoScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/diagnostics',
      builder: (context, state) => const DiagnosticsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);
