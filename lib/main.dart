import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/title_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Fullscreen immersive
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '台灣外送哥',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'NotoSansTC',
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFF5A623),
          secondary: const Color(0xFF4ECDC4),
          surface: const Color(0xFF1A1A2E),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const TitleScreen(),
      },
    );
  }
}
