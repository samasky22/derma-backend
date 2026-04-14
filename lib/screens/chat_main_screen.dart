import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'home_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatMainScreen extends StatefulWidget {
  final String userId;
  const ChatMainScreen({super.key, required this.userId});

  @override
  State<ChatMainScreen> createState() => _ChatMainScreenState();
}

class _ChatMainScreenState extends State<ChatMainScreen> {
  final String baseUrl = "http://192.168.1.18:8001";
  final TextEditingController controller = TextEditingController();

  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  // 🔥 الجديد
  bool isVoiceInput = false;

  List<ChatSession> chatSessions = [];
  List<Map<String, dynamic>> messages = [];
  String? currentChatId;
  bool isSidebarOpen = false;
  final Color customBlue = const Color(0xff5D8AA8);

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future<void> _speak(String text) async {
    bool isArabicText = isArabic(text);

    await flutterTts.stop();
    await flutterTts.setLanguage(isArabicText ? "ar-EG" : "en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.45);

    await flutterTts.speak(text);
  }

  void _listen() async {
    var status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) return;

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == "done") {
            setState(() => _isListening = false);

            if (controller.text.trim().isNotEmpty) {
              isVoiceInput = true;
              sendMessage(controller.text);
            }
          }
        },
        onError: (val) => print(val),
      );

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          onResult: (val) {
            setState(() {
              controller.text = val.recognizedWords;

              if (val.finalResult) {
                isVoiceInput = true;
              }
            });
          },
          localeId: 'ar_EG',
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 8),
          partialResults: true,
        );
      } else {
        setState(() => _isListening = false);
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  bool isArabic(String text) {
    return RegExp(r'^[\u0600-\u06FF]').hasMatch(text.trim());
  }

  void goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> loadChats() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/chats/${widget.userId}"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          chatSessions = (data as List)
              .map((e) => ChatSession.fromJson(e))
              .toList();
        });
      }
    } catch (e) {
      print("❌ Error loading chats: $e");
    }
  }

  Future<void> loadMessages(String chatId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/chat/$chatId"));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          messages = data.map((msg) {
            bool isBot = msg.toString().startsWith("Assistant:");
            return {
              "role": isBot ? "bot" : "user",
              "text": msg.toString().replaceFirst(
                isBot ? "Assistant: " : "User: ",
                "",
              ),
            };
          }).toList();
        });
      }
    } catch (e) {
      print("❌ Error loading messages: $e");
    }
  }

  void startNewChat() {
    setState(() {
      currentChatId = null;
      messages = [];
      isSidebarOpen = false;
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() => messages.add({"role": "user", "text": text}));
    controller.clear();

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "chat_id": currentChatId,
          "text": text,
        }),
      );

      final data = jsonDecode(res.body);

      if (currentChatId == null) currentChatId = data["chat_id"];

      final reply = (data["paragraphs"] as List).join("\n");

      setState(() => messages.add({"role": "bot", "text": reply}));

      if (isVoiceInput) {
        await _speak(reply);
        isVoiceInput = false;
      }

      loadChats();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              buildTopBar(),
              Expanded(child: buildMessages()),
              buildInput(),
            ],
          ),
          if (isSidebarOpen)
            Stack(
              children: [
                GestureDetector(
                  onTap: () => setState(() => isSidebarOpen = false),
                  child: Container(color: Colors.black26),
                ),
                buildSidebar(),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios, color: customBlue),
              onPressed: goHome,
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => setState(() => isSidebarOpen = true),
            ),
            const Expanded(
              child: Text(
                "Lateef",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: startNewChat,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMessages() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final isUser = msg["role"] == "user";
        final text = msg["text"] ?? "";
        final bool isTextArabic = isArabic(text);

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser ? customBlue : Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isUser ? 15 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 15),
              ),
            ),
            child: Text(
              text,
              textDirection: isTextArabic
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              textAlign: isTextArabic ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : customBlue,
            ),
            onPressed: _listen,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Describe your skin concern...",
                filled: true,
                fillColor: const Color.fromARGB(255, 231, 231, 231),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton.small(
            backgroundColor: customBlue,
            elevation: 0,
            onPressed: () => sendMessage(controller.text),
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget buildSidebar() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.80,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: customBlue.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(25.0),
              child: Text(
                "History",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: customBlue,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: customBlue, width: 1.5),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  "New Chat",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: startNewChat,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: chatSessions.length,
                itemBuilder: (context, i) {
                  final chat = chatSessions[i];
                  final isSelected = currentChatId == chat.chatId;

                  return ListTile(
                    leading: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: isSelected ? customBlue : Colors.grey[400],
                    ),
                    title: Text(
                      chat.title,
                      style: TextStyle(
                        color: isSelected ? customBlue : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        currentChatId = chat.chatId;
                        isSidebarOpen = false;
                      });
                      loadMessages(chat.chatId);
                    },
                  );
                },
              ),
            ),
            Divider(color: Colors.grey[100]),
            ListTile(
              leading: const Icon(Icons.home_outlined, color: Colors.grey),
              title: const Text("Home", style: TextStyle(color: Colors.grey)),
              onTap: goHome,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatSession {
  final String chatId;
  final String title;

  ChatSession({required this.chatId, required this.title});

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      chatId: json["chat_id"],
      title: json["title"] ?? "Untitled Chat",
    );
  }
}
