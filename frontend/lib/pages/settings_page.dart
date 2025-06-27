import 'package:flutter/material.dart';
import '../globals.dart';
import '../main.dart'; // To access appLocale
import '../generated/l10n.dart'; // For translated strings

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context)!.settingsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context)!.selectLanguage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<String>(
              valueListenable: appLanguage,
              builder: (context, value, _) {
                return Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(S.of(context)!.english),
                      value: 'en',
                      groupValue: value,
                      onChanged: (val) {
                        if (val != null) {
                          appLanguage.value = val;
                          appLocale.value = Locale(val); // triggers UI rebuild
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(S.of(context)!.kannada),
                      value: 'kn',
                      groupValue: value,
                      onChanged: (val) {
                        if (val != null) {
                          appLanguage.value = val;
                          appLocale.value = Locale(val); // triggers UI rebuild
                        }
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
