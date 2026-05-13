import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/onboarding/screens/module_selector_screen.dart';
import '../../features/onboarding/screens/equipment_selector_screen.dart';
import '../../features/journal/screens/journal_screen.dart';
import '../../features/journal/screens/add_meal_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/account/screens/account_screen.dart';
import '../../features/training/screens/workout_detail_screen.dart';
import '../../features/training/screens/live_workout_screen.dart';
import '../../features/training/screens/programs_screen.dart';
import '../../shared/widgets/shell_scaffold.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/journal',
    redirect: (context, state) {
      final status = authState.status;
      final loc = state.matchedLocation;

      if (status == AuthStatus.unknown) return null;

      final isAuth = status == AuthStatus.authenticated;
      final isAuthRoute = loc.startsWith('/login') || loc.startsWith('/register');
      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/journal';
      return null;
    },
    routes: [
      // Auth
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Onboarding
      GoRoute(
        path: '/onboarding/modules',
        builder: (_, __) => const ModuleSelectorScreen(),
      ),
      GoRoute(
        path: '/onboarding/equipment',
        builder: (_, __) => const EquipmentSelectorScreen(),
      ),

      // Main shell
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
        ],
      ),

      // Add meal (pushed from FAB)
      GoRoute(
        path: '/add-meal',
        builder: (_, state) => AddMealScreen(
          date: state.uri.queryParameters['date'] ?? DateTime.now().toIso8601String().substring(0, 10),
        ),
      ),

      // Account (pushed from journal avatar, not tab)
      GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),

      // Training programs list
      GoRoute(path: '/training/programs', builder: (_, __) => const ProgramsScreen()),

      // Training detail / live
      GoRoute(
        path: '/training/:id',
        builder: (_, state) =>
            WorkoutDetailScreen(workoutId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/training/:id/live',
        builder: (_, state) =>
            LiveWorkoutScreen(workoutId: state.pathParameters['id']!),
      ),
    ],
  );
}
