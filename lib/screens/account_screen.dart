import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gap/gap.dart';
import 'account/editprofile _screen.dart';
import 'account/changepassword_screen.dart';
import 'login_screen.dart';
import 'navbar_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserData() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage(onLoginSuccess: () {})),
    );
  }

  void _showEditNameBottomSheet(BuildContext context, String currentName) {
    final _controller = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Edit Name",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const Gap(20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final newName = _controller.text.trim();
                            if (newName.isEmpty) return;
                            final uid = FirebaseAuth.instance.currentUser!.uid;
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({'fullName': newName});
                            Navigator.pop(context);
                            setState(() {
                              _userDataFuture = _getUserData();
                            });
                          },
                          child: const Text(
                            "Save",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found'));
          }
          final userData = snapshot.data!.data()!;
          final String fullName = userData['fullName'] ?? 'User Name';
          final String email = userData['email'] ?? 'user@example.com';
          final String firstLetter = fullName.isNotEmpty ? fullName[0] : "U";

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18.h),
            child: Column(
              children: [
                Gap(15.h),
                _buildUserCard(
                  context,
                  char: firstLetter,
                  name: fullName,
                  email: email,
                ),
                Gap(20.h),
                _buildProfileOption("Edit Profile", Icons.person, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                }),
                _buildDivider(),
                _buildProfileOption("Change Password", Icons.lock, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UpdatePasswordScreen()),
                  );
                }),
                _buildDivider(),
                _buildProfileOption("Delete Account", Icons.delete, () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text("Delete Account"),
                          content: Text(
                            "Are you sure you want to delete your account? This action cannot be undone.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.black.withAlpha(
                                    (0.7 * 255).toInt(),
                                  ),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                  if (confirmed == true) {
                    try {
                      final user = FirebaseAuth.instance.currentUser!;
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .delete();
                      await user.delete();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => LoginPage(
                                onLoginSuccess: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const NavbarScreen(),
                                    ),
                                  );
                                },
                              ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to delete account: $e")),
                      );
                    }
                  }
                }),
                _buildDivider(),
                _buildProfileOption("Logout", Icons.logout, () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text("Logout"),
                          content: Text("Are you sure you want to logout?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.black.withAlpha(
                                    (0.7 * 255).toInt(),
                                  ),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                "Logout",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                  if (confirmed == true) _logout(context);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context, {
    required String char,
    required String name,
    required String email,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue, width: 1),
      ),
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25.w,
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Text(
            char,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          email,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: GestureDetector(
          onTap: () {
            _showEditNameBottomSheet(context, name);
          },
          child: Icon(Icons.edit, color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.black,
  }) {
    bool isRed = title == "Delete Account" || title == "Logout";
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isRed
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isRed ? Colors.red : Colors.blue),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isRed ? Colors.red : Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => Divider(color: Colors.grey, thickness: 1);
}
