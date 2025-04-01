import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';
import 'models/user_model.dart'; 
import 'admin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Reward App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
      // Add error boundary
      builder: (context, child) {
        ErrorWidget.builder = (errorDetails) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${errorDetails.exception}'),
            ),
          );
        };
        return child!;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.user == null) {
      return AuthScreen();
    } else {
      return MultiProvider(
        providers: [
          Provider.value(value: authProvider.user!),
          ChangeNotifierProvider(
            create: (_) => UserModel.fromFirebaseUser(authProvider.user!),
          ),
        ],
        child: HomeScreen(),
      );
    }
  }
}
