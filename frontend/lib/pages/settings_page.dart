import 'package:flutter/material.dart';
import '../globals.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select App Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ValueListenableBuilder<String>(
              valueListenable: appLanguage,
              builder: (context, value, _) {
                return Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('English'),
                      value: 'en',
                      groupValue: value,
                      onChanged: (val) {
                        if (val != null) appLanguage.value = val;
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Kannada'),
                      value: 'kn',
                      groupValue: value,
                      onChanged: (val) {
                        if (val != null) appLanguage.value = val;
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
