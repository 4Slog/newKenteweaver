import 'package:flutter/material.dart';

/// Animation constants used throughout the app
class AnimationConstants {
  // Standard durations
  static const Duration veryShort = Duration(milliseconds: 100);
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration veryLong = Duration(milliseconds: 800);

  // Standard curves
  static const Curve defaultEasing = Curves.easeInOut;
  static const Curve emphasisedEasing = Curves.easeOutBack;
  static const Curve bounceEasing = Curves.elasticOut;

  // Specific animation presets
  static const Duration tooltipDuration = Duration(milliseconds: 200);
  static const Duration modalTransitionDuration = Duration(milliseconds: 250);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration blockSnapDuration = Duration(milliseconds: 150);
  static const Duration feedbackPopupDuration = Duration(milliseconds: 400);
  
  // Achievement animations
  static const Duration achievementShowDuration = Duration(milliseconds: 800);
  static const Duration achievementHideDuration = Duration(milliseconds: 300);
  
  // Tutorial animations
  static const Duration tutorialStepTransition = Duration(milliseconds: 400);
  static const Duration tutorialHintPopup = Duration(milliseconds: 250);
  
  // Block workspace animations
  static const Duration blockDragAnimation = Duration(milliseconds: 150);
  static const Duration blockConnectAnimation = Duration(milliseconds: 300);
  static const Duration blockHighlightPulse = Duration(milliseconds: 600);
} 
