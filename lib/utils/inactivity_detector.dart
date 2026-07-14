import 'package:flutter/material.dart';
import '../utils/token_manager.dart';

class InactivityDetector extends StatelessWidget {
  final Widget child;

  const InactivityDetector({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;  // Just return the child widget directly
  }
}
