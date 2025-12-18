import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart'; // 🟢 Added
import 'dart:convert';

// Screens
import 'screens/login_screen.dart';
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

  // 🟢 Request permissions for notifications and vibration
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
        title: 'Smart Kangaroo Mother Care monitoring app',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.pink,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
                color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/reset_password': (context) => const ResetPasswordScreen(),
          '/home': (context) => const MainAppShell(),
          '/sleep_history': (context) => const SleepHistoryScreen(),
          '/feeding_history': (context) => const FeedingHistoryScreen(),
          '/bluetooth': (context) => const bls.BluetoothConnectionScreen(),
          '/reminders': (context) => const ReminderScreen(),
        },
      ),
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),
    const ReminderScreen(),
    const SleepHistoryScreen(),
    const FeedingHistoryScreen(),
    const AlertsScreen(),
    const SettingsScreen(),
    const bls.BluetoothConnectionScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String userId =
        Provider.of<AuthService>(context).currentUser?.uid ?? 'N/A';

    return Scaffold(

      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
          BottomNavigationBarItem(icon: Icon(Icons.king_bed), label: 'Sleep'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_dining), label: 'Feeding'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bluetooth), label: 'Bluetooth'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
