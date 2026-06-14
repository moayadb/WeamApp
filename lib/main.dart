import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const WeamApp());
}

class WeamApp extends StatefulWidget {
  const WeamApp({Key? key}) : super(key: key);

  @override
  State<WeamApp> createState() => _WeamAppState();
}

class _WeamAppState extends State<WeamApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'وئام — Weam',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0e9384),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0e9384),
                brightness: Brightness.dark,
              ),
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [
              Locale('ar', 'SA'),
              Locale('en', 'US'),
            ],
            home: const ChatScreen(),
          );
        },
      ),
    );
  }
}
