# Kente Codeweaver

An educational app teaching coding principles through traditional Kente weaving.

## Project Structure

```
lib/
├── core/                      # Core application code
│   ├── app.dart              # Main app configuration
│   ├── initialization.dart    # App initialization logic
│   └── constants.dart         # App-wide constants
│
├── features/                  # Feature-based organization
│   ├── story/                # Story-related features
│   │   ├── models/
│   │   ├── services/
│   │   ├── widgets/
│   │   └── screens/
│   │
│   ├── pattern/              # Pattern-related features
│   │   ├── models/
│   │   ├── services/
│   │   ├── widgets/
│   │   └── screens/
│   │
│   └── tutorial/             # Tutorial-related features
│       ├── models/
│       ├── services/
│       ├── widgets/
│       └── screens/
│
├── shared/                   # Shared components
│   ├── widgets/             # Common widgets
│   ├── services/            # Core services
│   ├── models/              # Common models
│   └── utils/               # Utility functions
│
└── config/                   # Configuration
    ├── theme/               # Theme configuration
    ├── routes/              # Navigation routes
    └── localization/        # Localization files
```

## Assets Organization

```
assets/
├── audio/                    # All audio files
│   ├── background/           # Background music
│   ├── effects/             # Sound effects
│   └── voice/               # Voice-overs
│
├── images/
│   ├── patterns/            # Pattern images
│   │   ├── basic/
│   │   ├── intermediate/
│   │   └── advanced/
│   ├── characters/          # Character images
│   ├── backgrounds/         # Background images
│   └── icons/              # App icons
│
├── animations/
│   ├── onboarding/         # Onboarding animations
│   ├── transitions/        # Screen transition animations
│   └── celebrations/       # Achievement animations
│
└── data/                    # Static data files
    ├── patterns.json        # Pattern definitions
    ├── stories.json        # Story content
    └── tutorials.json       # Tutorial content
```

## Setup

1. Install Flutter (version 3.0.0 or higher)
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Create a `.env` file in the root directory with the required environment variables
5. Run `flutter run` to start the app

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```
API_URL=your_api_url
API_KEY=your_api_key
```

## Dependencies

The project uses the following major dependencies:

- Flutter SDK (>=3.0.0 <4.0.0)
- Provider for state management
- AudioPlayers for audio playback
- Google Fonts for typography
- Device Info Plus for device information
- Flutter Secure Storage for secure data storage
- Path Provider for file system access
- UUID for unique identifier generation

## Development

- Use `flutter analyze` to check for linting issues
- Use `flutter test` to run tests
- Follow the feature-based directory structure for new features
- Keep shared components in the `shared` directory
- Use the provided services for device, audio, and pattern management

## Testing

The project includes:
- Unit tests for services and models
- Widget tests for UI components
- Integration tests for user flows

Run tests with:
```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and ensure they pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 