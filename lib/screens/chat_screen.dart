import 'package:flutter/material.dart';
import 'package:tbib_finder/widget/custom_button.dart';
import 'chatbot_screen.dart';
import '../widget/contact_card.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildChatCard(context),
            const SizedBox(height: 32),
            _buildContactsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 0.5),
      ),
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI Health Assistant",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Chatbot can help you with your medical questions",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  CustomButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatbotScreen(),
                        ),
                      );
                    },
                    text: 'Start Chat',
                    backgroundColor: Colors.blue,
                  ),
                ],
              ),
            ),
            Expanded(flex: 1, child: Image.asset("assets/images/chatbot.png")),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ContactCard(
          icon: Icons.local_hospital,
          title: "Ambulance",
          number: "190",
          color: Colors.green,
        ),
        ContactCard(
          icon: Icons.local_police,
          title: "Police",
          number: "197",
          color: Colors.blue,
        ),
        ContactCard(
          icon: Icons.fire_truck,
          title: "Firefighting",
          number: "198",
          color: Colors.orange,
        ),
      ],
    );
  }
}
