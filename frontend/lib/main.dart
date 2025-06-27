import 'package:flutter/material.dart';

import 'globals.dart';
import 'pages/chatbot_page.dart';
import 'pages/help_articles_page.dart';
import 'pages/price_forecast_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'Agri App',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.green,
          ),
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
        );
      },
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat), label: "Chatbot"),
          NavigationDestination(icon: Icon(Icons.menu_book), label: "Guides"),
          NavigationDestination(icon: Icon(Icons.price_change), label: "Price"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}