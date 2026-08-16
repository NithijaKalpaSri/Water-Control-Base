import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homePage.dart';
import 'history.dart';
import 'loginPage.dart';
import 'services/firebase_service.dart';
import 'widgets/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    // Force sign out every time the app starts to show the profile selection/login page
    await FirebaseAuth.instance.signOut();
    debugPrint('Firebase Initialized Successfully');
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }

  runApp(const SmartWaterTankApp());
}

class SmartWaterTankApp extends StatelessWidget {
  const SmartWaterTankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FirebaseService(),
      child: MaterialApp(
        title: 'Smart Water Tank',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        ),
        // Enforces login before showing dashboard
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebase = Provider.of<FirebaseService>(context);
    // Check our local boolean state instead of relying on network streams
    if (!firebase.isSignedInLocal) {
      return const LoginPage();
    }
    
    // Only show MainNavigationLayout if explicitly signed in
    return const MainNavigationLayout();
  }
}

class MainNavigationLayout extends StatefulWidget {
  const MainNavigationLayout({super.key});

  @override
  State<MainNavigationLayout> createState() => _MainNavigationLayoutState();
}

class _MainNavigationLayoutState extends State<MainNavigationLayout> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const HistoryPage(type: 'filling'),
    const HistoryPage(type: 'wastage'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: AppColors.deepBlue.withOpacity(0.9),
            indicatorColor: AppColors.primaryBlue,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Colors.white),
                selectedIcon: Icon(Icons.home, color: Colors.white),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.water_drop_outlined, color: Colors.white),
                selectedIcon: Icon(Icons.water_drop, color: Colors.white),
                label: 'Filling',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.restore_from_trash_outlined,
                  color: Colors.white,
                ),
                selectedIcon: Icon(
                  Icons.restore_from_trash,
                  color: Colors.white,
                ),
                label: 'Usage',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
