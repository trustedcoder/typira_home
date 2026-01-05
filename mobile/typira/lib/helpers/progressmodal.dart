import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  final String message;

  const ProgressDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
    child: Dialog(
      child: Padding(
        padding:  const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const SizedBox(
              width: 30.0,
              height: 30.0,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(
              width: 20.0,
            ),
            Text(message,
            style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ),);
  }
}