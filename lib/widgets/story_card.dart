import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StoryCard extends StatelessWidget {
  final String title;
  final String description;
  final String image;
  final bool isLocked;
  final VoidCallback? onTap;

  const StoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                  if (isLocked)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isLocked ? Colors.grey : AppTheme.kenteGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isLocked ? Colors.grey : null,
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
} 