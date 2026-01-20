import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

// Screens
import 'screens/login_screen.dart';
import 'screens/main_screen.dart'; // 🆕 NEW: Modern main screen with drawer
import 'screens/dashboard_screen.dart';
import 'screens/bluetooth_connection_screen.dart' as bls;
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/register_screen.dart';
import 'screens/sleep_history_screen.dart';
import 'screens/feeding_history_screen.dart';
import 'screens/reminder_screen.dart';
import 'screens/history_screen.dart';

// Services
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/bluetooth_service.dart';
import 'services/notification_service.dart';

// Global variables provided by the Canvas environment
// DO NOT MODIFY THESE LINES
// ignore_for_file: non_constant_identifier_names
final String __app_id = 'default-app-id';
final String __firebase_config = '{}';
final String __initial_auth_token = '';
// ignore_for_file: non_constant_identifier_names

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the provided configuration
  try {
    final firebaseConfig = Map<String, dynamic>.from(
      (__firebase_config.isNotEmpty)
          ? jsonDecode(__firebase_config)
          : {},
    );
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: firebaseConfig['apiKey'] ?? 'AIzaSyCsUebg_FhlO6RE7peMLwlUmDLg32GOhK0',
        appId: firebaseConfig['appId'] ?? '1:953406452006:android:582a89df8ac2fbf3d591e7',
        messagingSenderId:
        firebaseConfig['messagingSenderId'] ?? '953406452006',
        projectId: firebaseConfig['projectId'] ?? 'smartkmcapp',
        storageBucket: firebaseConfig['storageBucket'] ?? 'YOUR_STORAGE_BUCKET',
      ),
    );

    // Sign in with custom token or anonymously
    final auth = FirebaseAuth.instance;
    if (__initial_auth_token.isNotEmpty) {
      await auth.signInWithCustomToken(__initial_auth_token);
    } else {
      await auth.signInAnonymously();
    }
  } catch (e) {
    print('Error initializing Firebase or signing in: $e');
  }

  // Request permissions for notifications and vibration
  await Permission.notification.request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<BluetoothService>(
          create: (_) => BluetoothService(),
        ),
        // ChangeNotifierProxyProvider ensures DataService uses the correct UID
        ChangeNotifierProxyProvider<AuthService, DataService>(
          create: (_) => DataService('placeholder'),
          update: (_, authService, previousDataService) {
            final userId = authService.currentUser?.uid ?? 'placeholder';

            // Only create a new DataService instance if the user ID has changed
            if (previousDataService == null ||
                previousDataService.userId != userId) {
              return DataService(userId);
            }

            return previousDataService;
          },
        ),
        Provider<FirebaseAuth>(
          create: (_) => FirebaseAuth.instance,
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Kangaroo Mother Care',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.pink,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: Colors.white,

          // Modern AppBar Theme
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            centerTitle: false,
          ),

          // Modern Card Theme
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),
          ),

          // Modern Button Theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Modern Input Theme
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),

          // Color Scheme
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.pink,
            primary: Colors.pink[400]!,
            secondary: Colors.purple[400]!,
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/reset_password': (context) => const ResetPasswordScreen(),
          '/home': (context) => const MainScreen(), // 🆕 NEW: Modern main screen
          '/sleep_history': (context) => const SleepHistoryScreen(),
          '/feeding_history': (context) => const FeedingHistoryScreen(),
          '/bluetooth': (context) => const bls.BluetoothConnectionScreen(),
          '/reminders': (context) => const ReminderScreen(),
        },
      ),
    );
  }
}