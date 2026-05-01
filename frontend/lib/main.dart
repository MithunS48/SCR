import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/usage_provider.dart';
import 'core/providers/report_provider.dart';
import 'core/providers/event_provider.dart';
import 'core/providers/awareness_provider.dart';
import 'core/providers/gamification_provider.dart';
import 'core/router/app_router.dart';
import 'features/auth/screens/login_screen.dart';
import 'shared/widgets/user_nav_shell.dart';
import 'shared/widgets/admin_nav_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PlasticWatchApp());
}

class PlasticWatchApp extends StatelessWidget {
  const PlasticWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UsageProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AwarenessProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'PlasticWatch',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: _resolveHome(auth),
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }

  Widget _resolveHome(AuthProvider auth) {
    if (!auth.isAuthenticated) return const LoginScreen();
    if (auth.isAdmin) return const AdminNavShell();
    return const UserNavShell();
  }
}
