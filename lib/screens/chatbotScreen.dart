import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'chat_main_screen.dart';

class ChatbotIntroApp extends StatelessWidget {
  const ChatbotIntroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chatbot Intro',
      home: ChatbotIntroScreen(),
    );
  }
}

class ChatbotIntroScreen extends StatelessWidget {
  const ChatbotIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// Back arrow
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              /// Robot Image
              Expanded(
                child: Center(
                  child: Image.asset(
                    "assets/robo.jpeg",
                    width: 400,
                    height: 400,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Title
              const Text(
                "Your Medical Assistant",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              /// Description
              const Text(
                "“Meet Lateef, your medical assistant who helps you understand your condition and gives you personalized advice based on your health.”",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              /// Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatMainScreen(
                          userId: "1", // 👈 حطي هنا id الحقيقي بتاع المستخدم
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff5D8AA8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
