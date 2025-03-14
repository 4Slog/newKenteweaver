# Create new directory structure
$directories = @(
    "lib/core",
    "lib/features/story/models",
    "lib/features/story/services",
    "lib/features/story/widgets",
    "lib/features/story/screens",
    "lib/features/pattern/models",
    "lib/features/pattern/services",
    "lib/features/pattern/widgets",
    "lib/features/pattern/screens",
    "lib/features/tutorial/models",
    "lib/features/tutorial/services",
    "lib/features/tutorial/widgets",
    "lib/features/tutorial/screens",
    "lib/shared/widgets",
    "lib/shared/services",
    "lib/shared/models",
    "lib/shared/utils",
    "lib/config/theme",
    "lib/config/routes",
    "lib/config/localization",
    "assets/audio/background",
    "assets/audio/effects",
    "assets/audio/voice",
    "assets/images/patterns/basic",
    "assets/images/patterns/intermediate",
    "assets/images/patterns/advanced",
    "assets/images/characters",
    "assets/images/backgrounds",
    "assets/images/icons",
    "assets/animations/onboarding",
    "assets/animations/transitions",
    "assets/animations/celebrations",
    "assets/data",
    "test/features/story",
    "test/features/pattern",
    "test/features/tutorial",
    "test/shared/widgets",
    "test/shared/services",
    "test/integration/flows",
    "test/integration/scenarios"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Force -Path $dir
}

# Move files to their new locations
# Core files
Move-Item -Path "lib/app.dart" -Destination "lib/core/app.dart" -Force
Move-Item -Path "lib/main.dart" -Destination "lib/core/main.dart" -Force

# Move story-related files
Move-Item -Path "lib/screens/story_screen.dart" -Destination "lib/features/story/screens/story_screen.dart" -Force
Move-Item -Path "lib/models/story_model.dart" -Destination "lib/features/story/models/story_model.dart" -Force
Move-Item -Path "lib/services/story_engine_service.dart" -Destination "lib/features/story/services/story_engine_service.dart" -Force

# Move pattern-related files
Move-Item -Path "lib/widgets/smart_workspace.dart" -Destination "lib/features/pattern/widgets/pattern_workspace.dart" -Force
Move-Item -Path "lib/widgets/ai_mentor_widget.dart" -Destination "lib/features/pattern/widgets/pattern_mentor.dart" -Force

# Move test files
Move-Item -Path "test/widget/components/smart_workspace_test.dart" -Destination "test/features/pattern/pattern_workspace_test.dart" -Force
Move-Item -Path "test/widget/components/ai_mentor_widget_test.dart" -Destination "test/features/pattern/pattern_mentor_test.dart" -Force

# Move assets
Move-Item -Path "assets/music/*" -Destination "assets/audio/background/" -Force
Move-Item -Path "assets/documents/*" -Destination "assets/data/" -Force

# Create new data files
@"
{
    "version": "1.0.0",
    "patterns": []
}
"@ | Out-File -FilePath "assets/data/patterns.json" -Encoding UTF8

@"
{
    "version": "1.0.0",
    "stories": []
}
"@ | Out-File -FilePath "assets/data/stories.json" -Encoding UTF8

@"
{
    "version": "1.0.0",
    "tutorials": []
}
"@ | Out-File -FilePath "assets/data/tutorials.json" -Encoding UTF8

Write-Host "Migration completed successfully!" 