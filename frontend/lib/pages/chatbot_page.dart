import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../globals.dart';
import '../generated/l10n.dart'; // Import localization

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  Future<void> sendMessage(String lang) async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'message': userInput});
      _loading = true;
      _controller.clear();
    });

    final response = await http.post(
      Uri.parse('http://localhost:8000/crop-rotation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'lang': lang,
        'user_paragraph': userInput,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final botMessage = data['crop_rotation_advice'];

      setState(() {
        _messages.add({'sender': 'bot', 'message': botMessage});
        _loading = false;
      });
    } else {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'message': S.of(context)!.errorMessage, // localized error message
        });
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(title: Text(S.of(context)!.chatbotTitle)),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, idx) {
                    final msg = _messages[idx];
                    final isUser = msg['sender'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(msg['message'] ?? ''),
                      ),
                    );
                  },
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(labelText: S.of(context)!.inputHint),
                        onSubmitted: (_) => sendMessage(lang),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : () => sendMessage(lang),
                      child: Text(S.of(context)!.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
