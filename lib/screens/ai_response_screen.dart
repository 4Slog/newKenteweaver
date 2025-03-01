import 'package:flutter/material.dart';

class AIResponseScreen extends StatelessWidget {
  final String feedback; // Feedback message from AI

  const AIResponseScreen({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Improved back navigation
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFeedbackCard(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), // Go back to previous screen
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget to display AI feedback with checkmark ✅❌
  Widget _buildFeedbackCard() {
    bool isSuccess = feedback.toLowerCase().contains("success") ||
        feedback.toLowerCase().contains("completed") ||
        !feedback.toLowerCase().contains("error");

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 50,
            ),
            const SizedBox(height: 10),
            Text(
              feedback,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
