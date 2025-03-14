# Utils Directory

This directory contains utility functions and helper classes that are used across the application. These utilities are focused on specific, reusable functionality that doesn't fit into the service or model categories.

## Current Utilities

### UI & Animation
- `screen_transitions.dart`: Provides custom screen transition animations and effects

### Data Conversion
- `block_collection_converter.dart`: Converts between different block collection formats

## When to Add to Utils

Add code to this directory when it:
1. Provides pure utility functions without state
2. Is used across multiple parts of the application
3. Doesn't fit into services, models, or widgets
4. Is focused on a specific, reusable task

## Best Practices

When adding utilities:
1. Keep functions pure and stateless
2. Document all public functions and classes
3. Include unit tests for complex logic
4. Avoid dependencies on services or business logic
5. Keep files focused on a single responsibility 