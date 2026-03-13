import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/video_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SoundWaveApp());
}

class SoundWaveApp extends StatelessWidget {
  const SoundWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..init(),
        ),
        ChangeNotifierProvider<MusicProvider>(
          create: (_) => MusicProvider(),
        ),
        ChangeNotifierProvider<VideoProvider>(
          create: (_) => VideoProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'SoundWave',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: auth.isInitializing
                ? const _SplashScreen()
                : (auth.firebaseUser == null
                    ? const LoginScreen()
                    : const HomeScreen()),
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF060610),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC62AFF)),
        ),
      ),
    );
  }
}

