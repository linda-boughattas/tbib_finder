import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({Key? key}) : super(key: key);

  @override
  _UpdatePasswordScreenState createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _passwordError = '';

  Future<bool> _updatePassword(String oldPassword, String newPassword) async {
    try {
      User user = FirebaseAuth.instance.currentUser!;
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      // Reauthenticate the user
      await user.reauthenticateWithCredential(credential);

      // Update the password
      await user.updatePassword(newPassword);

      Fluttertoast.showToast(msg: "Password updated successfully");
      return true;
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'wrong-password') {
        setState(() {
          _passwordError = 'Incorrect old password. Please try again.';
        });
      } else {
        Fluttertoast.showToast(msg: "Error updating password: $e");
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Update Password", style: TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter, // Horizontal center only
          child: Container(
            margin: const EdgeInsets.only(top: 40), // Top margin
            width:
                MediaQuery.of(context).size.width *
                0.85, // Optional width constraint
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Old Password Input
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: _oldPasswordController,
                          labelText: "Old Password",
                          borderColor: Colors.grey,
                          fillColor: Colors.white,
                          isPassword: true,
                        ),
                        if (_passwordError.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _passwordError,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // New Password Input
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomTextField(
                      controller: _newPasswordController,
                      labelText: "New Password",
                      borderColor: Colors.grey,
                      fillColor: Colors.white,
                      isPassword: true,
                    ),
                  ),
                  // Confirm Password Input
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CustomTextField(
                      controller: _confirmPasswordController,
                      labelText: "Confirm Password",
                      borderColor: Colors.grey,
                      fillColor: Colors.white,
                      isPassword: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        if (_oldPasswordController.text.isEmpty) {
                          setState(() {
                            _passwordError = 'Please enter your old password';
                          });
                          return;
                        }

                        if (_newPasswordController.text.length < 6) {
                          Fluttertoast.showToast(
                            msg: 'Password must be at least 6 characters',
                          );
                          return;
                        }

                        if (_newPasswordController.text !=
                            _confirmPasswordController.text) {
                          Fluttertoast.showToast(msg: 'Passwords do not match');
                          return;
                        }

                        bool success = await _updatePassword(
                          _oldPasswordController.text.trim(),
                          _newPasswordController.text.trim(),
                        );
                        if (success) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    text: "Update Password",
                    backgroundColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
