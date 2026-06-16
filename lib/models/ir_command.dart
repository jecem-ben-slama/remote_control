import 'package:flutter/material.dart';

/// Represents an IR command with its code and label
class IRCommand {
  final int code;
  final TextEditingController controller;

  IRCommand(this.code) : controller = TextEditingController();

  String get hex => '0x${code.toRadixString(16).toUpperCase().padLeft(2, '0')}';
  bool get hasLabel => controller.text.trim().isNotEmpty;

  /// Dispose resources
  void dispose() {
    controller.dispose();
  }
}
