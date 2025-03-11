# Services Directory

This directory contains the core services used by the Kente Codeweaver application. Each service is responsible for a specific aspect of the application's functionality.

## Core Services

### Device & Storage
- `device_profile_service.dart`: Manages user profiles, preferences, and progress tracking based on device
- `storage_service.dart`: Handles persistent storage operations and caching
- `progress_service.dart`: Tracks and manages user learning progress

### Story & Learning
- `story_engine_service.dart`: Main service for generating and managing interactive story content using AI
- `story_navigation_service.dart`: Handles navigation between story nodes and manages story state
- `story_progression_service.dart`: Manages story progression, unlocks, and adaptive difficulty
- `lesson_service.dart`: Manages learning content, lessons, and curriculum structure
- `adaptive_learning_service.dart`: Provides personalized learning paths and adaptive content

### Pattern & Block Management
- `pattern_render_service.dart`: Renders Kente patterns based on block configurations
- `pattern_analyzer_service.dart`: Analyzes patterns for correctness and provides feedback
- `block_definition_service.dart`: Defines and manages available coding blocks

### User Experience
- `audio_service.dart`: Handles background music and sound effects
- `tts_service.dart`: Provides text-to-speech functionality for story narration
- `tutorial_service.dart`: Manages interactive tutorials and help content
- `localization_service.dart`: Handles multi-language support and translations
- `logging_service.dart`: Manages application logging and debugging
- `navigation_service.dart`: Handles app-wide navigation and routing

### Achievement System
- `achievement_service.dart`: Manages achievements, rewards, and user progress tracking

## Service Organization

The services are organized into three directories:
- `/services`: Active services used in production
- `/deprecated`: Old implementations and unused services
- `/experimental`: New features being tested

## Best Practices

When working with services:
1. Each service should have a single responsibility
2. Services should be stateless when possible
3. Use dependency injection for service dependencies
4. Document public methods and important implementation details
5. Include unit tests for critical functionality

## Service Dependencies

Important service dependencies:
- `story_engine_service.dart` depends on `device_profile_service.dart` and `storage_service.dart`
- `pattern_analyzer_service.dart` depends on `block_definition_service.dart`
- `story_navigation_service.dart` depends on `story_engine_service.dart` and `audio_service.dart` 