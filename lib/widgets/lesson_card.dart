import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/lesson_type.dart';
import 'difficulty_badge.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DifficultyBadge(difficulty: lesson.difficulty),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lesson.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (lesson.skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: lesson.skills.map((skill) {
                    return Chip(
                      label: Text(
                        skill,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue[50],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              if (lesson.prerequisites.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Prerequisites: ${lesson.prerequisites.join(", ")}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData iconData;
    Color color;

    switch (lesson.type) {
      case LessonType.tutorial:
        iconData = Icons.school;
        color = Colors.blue;
        break;
      case LessonType.pattern:
        iconData = Icons.grid_on;
        color = Colors.green;
        break;
      case LessonType.story:
        iconData = Icons.book;
        color = Colors.purple;
        break;
      case LessonType.challenge:
        iconData = Icons.star;
        color = Colors.orange;
        break;
      case LessonType.assessment:
        iconData = Icons.assignment;
        color = Colors.red;
        break;
      case LessonType.project:
        iconData = Icons.build;
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }
}
