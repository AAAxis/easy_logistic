import 'package:flutter/material.dart';

class AppleSignInButton extends StatelessWidget {
  final void Function() onPressed;

  AppleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text('Sign in with Apple'),
    );
  }
}