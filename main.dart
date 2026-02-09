import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/system_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user/user_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/super/super_dashboard.dart';

void main() async {
  // Wrap everything in a zone to catch all errors
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set up error handling for Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      }
    };
    
    ThemeProvider? themeProvider;
    LocaleProvider? localeProvider;
    
    try {
      // Initialize Firebase with error handling
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      // Continue running without Firebase if it fails
    }
    
    try {
      // Initialize ThemeProvider
      themeProvider = ThemeProvider();
      await themeProvider.init();
    } catch (e) {
      debugPrint('ThemeProvider initialization failed: $e');
      themeProvider = ThemeProvider();
    }

    try {
      // Initialize LocaleProvider
      localeProvider = LocaleProvider();
      await localeProvider.init();
    } catch (e) {
      debugPrint('LocaleProvider initialization failed: $e');
      localeProvider = LocaleProvider();
    }
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ComplaintProvider()),
          ChangeNotifierProvider(create: (_) => SystemProvider()),
          ChangeNotifierProvider.value(value: themeProvider!),
          ChangeNotifierProvider.value(value: localeProvider!),
        ],
        child: const ComplaintApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

class ComplaintApp extends StatelessWidget {
  const ComplaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return MaterialApp(
          title: 'Just Complaint',
          debugShowCheckedModeBanner: false,
          
          // Localization configuration
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ur'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          
          // Theme configuration - using default system fonts instead of Google Fonts
          // to avoid runtime font fetching issues in release mode
          themeMode: themeProvider.themeMode,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        debugPrint("AuthWrapper Rebuild: isInitialized=${auth.isInitialized}, isAuthenticated=${auth.isAuthenticated}, role=${auth.role}");
        
        if (!auth.isInitialized) {
          return const SplashScreen();
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        final role = auth.role?.trim().toLowerCase();
        switch (role) {
          case 'user':
            return const UserHomeScreen();
          case 'admin':
            return const AdminHomeScreen();
          case 'super':
          case 'super admin':
            return const SuperDashboard();
          default:
            debugPrint("AuthWrapper: Unknown role '$role', falling back to login.");
            return const LoginScreen();
        }
      },
    );
  }
}