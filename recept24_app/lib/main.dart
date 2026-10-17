import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/locale_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Recept24App());
}

class Recept24App extends StatelessWidget {
  const Recept24App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.currentLang,
      builder: (context, lang, _) {
        return MaterialApp(
          key: ValueKey(lang),
          title: 'Recept24',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Segoe UI',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F7FB),
            colorSchemeSeed: const Color(0xFF2563EB),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
