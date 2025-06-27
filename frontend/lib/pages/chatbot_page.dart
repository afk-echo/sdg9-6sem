import 'package:flutter/material.dart';
import '../globals.dart';

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

    // Replace this with your actual backend call
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _messages.add({'sender': 'bot', 'message': '[$lang] Bot reply for: $userInput'});
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Chatbot')),
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
                        decoration: const InputDecoration(labelText: 'Enter your query'),
                        onSubmitted: (_) => sendMessage(lang),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : () => sendMessage(lang),
                      child: const Text('Send'),
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
