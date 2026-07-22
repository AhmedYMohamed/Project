import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/officer_dashboard_screen.dart';
import 'screens/lawyer_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MoiReportingApp(),
    ),
  );
}

class MoiReportingApp extends StatelessWidget {
  const MoiReportingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'MoI Reporting System',
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF3B82F6),
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isInitialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (auth.isAuthenticated) {
            if (auth.selectedRole == 'officer') {
              return const OfficerDashboardScreen();
            } else if (auth.selectedRole == 'lawyer') {
              return const LawyerDashboardScreen();
            }
            return const MainNavigationScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
