import 'package:flutter/material.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> earnedRewards = [
      "Golden Stripe Pattern",
      "Diamond Weave",
      "Ananse’s Legacy Cloth"
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Rewards')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unlocked Kente Patterns:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: earnedRewards.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: const Icon(Icons.star, color: Colors.orange),
                      title: Text(earnedRewards[index]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement logic to view and use rewards
                },
                child: const Text('Use Rewards'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
