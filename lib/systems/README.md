# Systems Directory

This directory contains complex subsystems that combine multiple components to provide specific functionality. Unlike services which focus on single responsibilities, systems integrate multiple features and components to create larger functional units.

## Current Systems

### Pattern Preview
- Location: `/pattern_preview`
- Purpose: Handles the rendering and preview of Kente patterns
- Components:
  - Pattern image generation
  - Real-time preview rendering
  - Pattern analysis visualization
  - Interactive pattern manipulation

## When to Add to Systems

Add code to this directory when it:
1. Combines multiple components or services
2. Requires its own internal architecture
3. Is complex enough to warrant isolation
4. Has multiple related features working together

## Best Practices

When developing systems:
1. Keep each system isolated and self-contained
2. Document the system's architecture and components
3. Include integration tests
4. Maintain clear boundaries with other systems
5. Use dependency injection for external services 