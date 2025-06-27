import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart'; // Import for error types

import '../globals.dart';
import '../generated/l10n.dart'; // localization

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastError = '';
  String _lastStatus = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech(); // initialize once
  }

  Future<void> _initSpeech() async {
    debugPrint("Initializing speech recognition...");
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        setState(() {
          _lastStatus = status;
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        });
      },
      onError: (errorNotification) {
        debugPrint("Speech error: ${errorNotification.errorMsg}");
        setState(() {
          _lastError = errorNotification.errorMsg;
          _isListening = false;
        });
      },
      // Consider adding this for web if you experience issues with duplicates
      // options: [
      //   stt.SpeechToText.webDoNotAggregate, // This might help with web specific issues
      // ],
    );

    if (available) {
      debugPrint("Speech recognition available.");
      // You can list available locales for debugging
      // var locales = await _speech.locales();
      // for (var locale in locales) {
      //   debugPrint("Locale: ${locale.localeId} - ${locale.name}");
      // }
    } else {
      debugPrint("Speech recognition not available on this device/browser.");
      setState(() {
        _lastError = S.of(context)!.speechNotAvailable;
      });
    }
  }

  Future<void> _listen(String lang) async {
    // Check if speech recognition is available
    if (!_speech.isAvailable) {
      debugPrint("Speech recognition is not available to start listening.");
      setState(() {
        _lastError = S.of(context)!.speechNotAvailable;
      });
      return;
    }

    // `initialize` method already handles permission on first call.
    // We just need to check if we currently *have* permission before trying to listen.
    if (!await _speech.hasPermission) {
      debugPrint("Microphone permission not granted (or denied). Cannot start listening.");
      setState(() {
        _lastError = S.of(context)!.microphonePermissionDenied;
      });
      return;
    }

    if (!_isListening) {
      setState(() => _isListening = true);
      debugPrint("Starting to listen...");
      _speech.listen(
        localeId: lang == 'kn' ? 'kn_IN' : 'en_US',
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
          debugPrint("Recognized words: ${result.recognizedWords}");
        },
        listenFor: const Duration(seconds: 30), // Listen for a maximum of 30 seconds
        onSoundLevelChange: (level) {
          // debugPrint('Sound level: $level'); // Uncomment for detailed sound level logging
        },
        cancelOnError: true, // Stop listening if an error occurs
        partialResults: true, // Get intermediate results
      );
    } else {
      debugPrint("Stopping listening...");
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> sendMessage(String lang) async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'message': userInput});
      _loading = true;
      _controller.clear();
      _lastError = ''; // Clear previous errors on new message
    });

    // Replace with your actual backend URL
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
          'message': S.of(context)!.errorMessage,
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
              if (_lastError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _lastError,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      tooltip: _isListening ? S.of(context)!.listening : S.of(context)!.speak,
                      onPressed: () => _listen(lang),
                    ),
                    const SizedBox(width: 4),
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