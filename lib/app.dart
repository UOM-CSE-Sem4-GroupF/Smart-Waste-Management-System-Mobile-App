import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_provider.dart';
import 'features/login/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/job/job_detail_screen.dart';
import 'features/job/job_map_screen.dart';
import 'features/job/bin_collection_screen.dart';
import 'features/job/job_complete_screen.dart';
import 'features/history/history_screen.dart';
import 'features/history/history_detail_screen.dart';
import 'theme/app_theme.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Global navigator key — used by FCMService / SocketService to push routes.
GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

/// GoRouter — reads auth state for redirect
GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = ref.read(isLoggedInProvider);
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGoingToLogin) return '/login';
      if (isLoggedIn && isGoingToLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      // ⚠️  Static sub-routes must be declared BEFORE the dynamic :jobId route
      GoRoute(
        path: '/job/active/map',
        name: 'jobMap',
        builder: (_, __) => const JobMapScreen(),
      ),
      GoRoute(
        path: '/job/active/bin/:clusterId',
        name: 'binCollection',
        builder: (_, state) => BinCollectionScreen(
          clusterId: state.pathParameters['clusterId']!,
        ),
      ),
      GoRoute(
        path: '/job/complete',
        name: 'jobComplete',
        builder: (_, __) => const JobCompleteScreen(),
      ),
      GoRoute(
        path: '/job/:jobId',
        name: 'jobDetail',
        builder: (_, state) => JobDetailScreen(
          jobId: state.pathParameters['jobId']!,
        ),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/history/:jobId',
        name: 'historyDetail',
        builder: (_, state) => HistoryDetailScreen(
          jobId: state.pathParameters['jobId']!,
        ),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.accentRed, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? '',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  _rootNavigatorKey.currentContext?.go('/home'),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
  );
}

class WasteCollectApp extends ConsumerStatefulWidget {
  const WasteCollectApp({super.key});

  @override
  ConsumerState<WasteCollectApp> createState() => _WasteCollectAppState();
}

class _WasteCollectAppState extends ConsumerState<WasteCollectApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Build the router once — avoids the !_dirty assertion that occurs when a
    // new GoRouter is created on every rebuild (e.g. after auth state changes).
    _router = buildRouter(ref);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WasteCollect Driver',
      theme: AppTheme.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
