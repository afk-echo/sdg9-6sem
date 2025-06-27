import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'generated/l10n.dart'; // Auto-generated localization class
import 'globals.dart';
import 'pages/chatbot_page.dart';
import 'pages/help_articles_page.dart';
import 'pages/price_forecast_page.dart';
import 'pages/settings_page.dart';

ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

void main() {
  runApp(
    ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) => MyApp(locale: locale),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Locale locale;
  const MyApp({super.key, required this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agri App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('kn'),
      ],
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    ChatbotPage(),
    HelpArticlesPage(),
    PriceForecastPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat),
            label: S.of(context)!.appTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book),
            label: S.of(context)!.guides,
          ),
          NavigationDestination(
            icon: const Icon(Icons.price_change),
            label: S.of(context)!.price,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: S.of(context)!.settingsTitle,
          ),
        ],
      ),
    );
  }
}
