import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CharacterAvatar extends StatelessWidget {
  final String characterId;
  final double size;

  const CharacterAvatar({
    super.key,
    required this.characterId,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.kenteGold,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kenteGold.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/characters/$characterId.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.person,
                size: size * 0.6,
                color: Colors.grey[400],
              ),
            );
          },
        ),
      ),
    );
  }
} 