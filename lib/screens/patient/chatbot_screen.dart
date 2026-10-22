import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/chatbot_service.dart';

/// 24/7 Health Assistant Chatbot — rule-based, works fully offline,
/// mirroring the free chatbot on the web app.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatMessage {
  final String text;
  final bool fromUser;
  _ChatMessage(this.text, this.fromUser);
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      'Hi! I am the MedEase Health Assistant. Ask me about appointments, bills, prescriptions, lab results, or your queue token.',
      false,
    ),
  ];

  void _send([String? quick]) {
    final text = (quick ?? _controller.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text, true));
      _messages.add(_ChatMessage(ChatbotService.reply(text), false));
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const quickChips = ['Book appointment', 'My bills', 'Cancel appointment', 'Lab results'];
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(radius: 14, backgroundColor: MedEaseColors.primaryLight, child: Icon(Icons.smart_toy_outlined, size: 16, color: MedEaseColors.primary)),
            SizedBox(width: 10),
            Text('Health Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: m.fromUser ? MedEaseColors.primary : MedEaseColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(color: m.fromUser ? Colors.white : MedEaseColors.ink, fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: quickChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ActionChip(
                label: Text(quickChips[i], style: const TextStyle(fontSize: 12)),
                onPressed: () => _send(quickChips[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Ask something…'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _send(),
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(backgroundColor: MedEaseColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
