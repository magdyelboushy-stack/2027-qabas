import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:mihrab/core/translations/app_locale_keys.dart';
import '../../../auth/data/auth_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  String? _userId;
  Timer? _timer;
  bool _isSending = false;

  // --- Live Server URL ---
  final String _baseUrl = 'https://mihrab-app.alwaysdata.net/api/chat';

  @override
  void initState() {
    super.initState();
    _initUserAndLoad();
    // Poll messages every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _fetchMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initUserAndLoad() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      setState(() => _userId = user['id'].toString());
      _fetchMessages();
    }
  }

  Future<void> _fetchMessages() async {
    if (_userId == null) return;
    try {
      // Fetch messages from server
      final url = Uri.parse('$_baseUrl/read.php?user_id=$_userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _messages = data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      // Error loading chat
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || _userId == null) return;

    final text = _controller.text;
    _controller.clear(); // Clear field immediately
    setState(() => _isSending = true);

    try {
      // Send to server
      await http.post(
        Uri.parse('$_baseUrl/send.php'),
        body: json.encode({
          'user_id': _userId,
          'sender': 'user',
          'message': text
        }),
      );

      await _fetchMessages(); // Instant refresh
      _scrollToBottom(); // Scroll down

    } catch (e) {
      // Error sending message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocaleKeys.failedSendMessage.tr)),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60, // +60 padding to see last message
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Support', style: TextStyle( fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF1E4D3E),
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E4D3E), Color(0xFF0E241E)],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? const Center(child: Text("Start a conversation with support", style: TextStyle(color: Colors.white54, )))
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['sender'] == 'user';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.cyanAccent.withOpacity(0.8) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          msg['message'],
                          style: TextStyle(
                            color: isMe ? Colors.black : Colors.white,
                            
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Input Field
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E4D3E),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white, ),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _isSending ? null : _sendMessage,
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.cyanAccent,
                        child: _isSending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.send_rounded, color: Colors.black, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}