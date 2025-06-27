import 'package:flutter/material.dart';

class LanguagePickerDialog extends StatelessWidget {
  final String initialLocale;
  const LanguagePickerDialog({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    final languages = [
      {'label': 'English', 'locale': 'en_US'},
      {'label': 'Kannada', 'locale': 'kn_IN'},
      {'label': 'Hindi', 'locale': 'hi_IN'},
      // Add more as needed
    ];
    return SimpleDialog(
      title: const Text('Select language'),
      children: languages
          .map((lang) => RadioListTile(
                value: lang['locale'],
                groupValue: initialLocale,
                title: Text(lang['label']!),
                onChanged: (val) => Navigator.pop(context, val),
              ))
          .toList(),
    );
  }
}
