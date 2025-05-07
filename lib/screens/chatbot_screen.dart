import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ChatUser? _currentUser;
  final ChatUser _mistralChatUser = ChatUser(
    id: '2',
    firstName: ' ',
    lastName: 'Chatbot',
  );
  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<ChatUser> _typingUsers = <ChatUser>[];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _chatHistory = [];
  String? _activeChatId;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (snapshot.exists) {
      final userData = snapshot.data()!;
      setState(() {
        _currentUser = ChatUser(
          id: userId,
          firstName: userData['firstName'] ?? 'Unknown',
          lastName: userData['lastName'] ?? 'User',
        );
      });
      Future.microtask(() => _loadChatHistory());
    }
  }

  Future<void> _loadChatHistory() async {
    final history =
        await FirebaseFirestore.instance
            .collection('chats')
            .where('userId', isEqualTo: _currentUser!.id)
            .orderBy('timestamp', descending: true)
            .get();

    for (var doc in history.docs) {
      print("Chat: ${doc.id} => ${doc.data()}");
    }

    setState(() {
      _chatHistory = history.docs;
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent.withAlpha(30),
        title: Text("AI Health Assistant", style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_outlined, color: Colors.black),
            onPressed: _openDrawer,
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            children:
                _chatHistory.isEmpty
                    ? [Center(child: Text("No chat history available"))]
                    : _chatHistory.map((doc) {
                      final data = doc.data();
                      final timestamp =
                          (data['timestamp'] as Timestamp).toDate();
                      return ListTile(
                        title: Text(data['title'] ?? 'Untitled'),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(timestamp),
                        ),
                        onTap: () async {
                          final messagesSnap =
                              await doc.reference
                                  .collection('messages')
                                  .orderBy('createdAt', descending: true)
                                  .get();
                          final loadedMessages =
                              messagesSnap.docs.map((msg) {
                                final msgData = msg.data();
                                return ChatMessage(
                                  text: msgData['text'],
                                  user: ChatUser(id: msgData['userId']),
                                  createdAt:
                                      (msgData['createdAt'] as Timestamp)
                                          .toDate(),
                                );
                              }).toList();

                          setState(() {
                            _activeChatId = doc.id;
                            _messages.clear();
                            _messages.addAll(loadedMessages);
                          });

                          Navigator.pop(context);
                        },
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            await doc.reference.delete();
                            _loadChatHistory();
                          },
                        ),
                      );
                    }).toList(),
          ),
        ),
      ),
      body:
          _currentUser == null
              ? const Center(child: CircularProgressIndicator())
              : Container(
                color: Colors.lightBlueAccent.withAlpha(30),
                child: Stack(
                  children: [
                    DashChat(
                      currentUser: _currentUser!,
                      typingUsers: _typingUsers,
                      messageOptions: const MessageOptions(
                        currentUserContainerColor: Colors.lightBlue,
                        currentUserTextColor: Colors.white,
                        containerColor: Colors.white,
                        textColor: Colors.black,
                      ),
                      onSend: (ChatMessage m) {
                        getChatResponse(m);
                      },
                      messages: _messages,
                    ),
                    if (_messages.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/chatbot2.png',
                              height: 150,
                              width: 150,
                            ),
                            Text(
                              "Start Chatting",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromRGBO(5, 57, 73, 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m);
      _typingUsers.add(_mistralChatUser);
    });

    await _saveMessage(m);

    final List<Map<String, String>> chatHistory =
        _messages.reversed.map((msg) {
          return {
            "role": msg.user.id == _currentUser?.id ? "user" : "assistant",
            "content": msg.text,
          };
        }).toList();

    final url = Uri.parse(
      'https://router.huggingface.co/together/v1/chat/completions',
    );
    final headers = {
      'Authorization': 'Bearer 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',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      "messages": chatHistory,
      "max_tokens": 200,
      "model": "mistralai/Mistral-7B-Instruct-v0.3",
      "stream": false,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode != 200) {
        throw Exception('http.post error: statusCode= ${response.statusCode}');
      }

      print(response.body);

      final decoded = json.decode(response.body);
      final String reply =
          decoded["choices"][0]["message"]["content"] ?? "No response";
      _addMessage(reply);
    } catch (e) {
      _addMessage("Request failed: $e");
    } finally {
      setState(() {
        _typingUsers.remove(_mistralChatUser);
      });
    }
  }

  Future<void> _saveMessage(ChatMessage msg) async {
    final chats = FirebaseFirestore.instance.collection('chats');
    final timestamp = Timestamp.now();

    if (_activeChatId == null) {
      final doc = await chats.add({
        'userId': _currentUser!.id,
        'title': msg.text.length > 30 ? msg.text.substring(0, 30) : msg.text,
        'timestamp': timestamp,
      });
      _activeChatId = doc.id;
      _loadChatHistory();
    }

    await chats.doc(_activeChatId).collection('messages').add({
      'text': msg.text,
      'userId': msg.user.id,
      'createdAt': timestamp,
    });
  }

  void _addMessage(String text) {
    final reply = ChatMessage(
      user: _mistralChatUser,
      createdAt: DateTime.now(),
      text: text,
    );

    setState(() {
      _messages.insert(0, reply);
    });

    _saveMessage(reply);
  }
}
