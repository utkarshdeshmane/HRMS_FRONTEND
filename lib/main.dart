import 'package:flutter/material.dart';
import 'repository/screens/sidebar/hrms_sidebar.dart';
import 'repository/screens/dashboard/dashboard.dart';
import 'repository/screens/auth/splash_screen.dart';
import 'config/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HRMS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Change to ThemeMode.system for auto dark mode
      home: const SplashScreen(), // Start with splash screen for authentication check
    );
  }
}

class HomeLayout extends StatefulWidget {
  
  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      drawer: isMobile ? Drawer(child: HRMSSidebar()) : null,

      body: Row(
        children: [
          if (!isMobile) HRMSSidebar(),  // Sidebar always visible on web desktop

          Expanded(
            child: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
