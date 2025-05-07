import 'package:flutter/material.dart';

class CustomMessage {
  static SnackBar show({
    required String message,
    Color backgroundColor = const Color.fromARGB(
      77,
      0,
      0,
      0,
    ), // black with alpha 0.3
    Duration duration = const Duration(seconds: 2),
  }) {
    return SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
    );
  }
}
