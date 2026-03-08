# Project: Flutter Wallet App

## Overview
This project is a Flutter application that is being refactored from an older codebase to a modern, maintainable architecture.

## Primary Goals
- Modernize outdated Flutter code
- Keep the app stable during refactoring
- Improve readability and maintainability
- Reduce large widget complexity
- Remove deprecated APIs
- Apply null safety correctly
- Improve folder and feature structure

## Architecture
Preferred architecture:
- Feature-based folder structure
- MVVM or Clean Architecture
- Repository pattern
- Separation of UI / state / domain / data responsibilities

Recommended structure example:
- lib/core
- lib/features
- lib/shared

Within each feature:
- presentation/
- application/ or viewmodel/
- domain/
- data/

## State Management
Preferred state management:
- Riverpod first
- Provider is acceptable if migration must be incremental

## Coding Rules
- Use null safety
- Avoid deprecated APIs
- Keep widgets small and reusable
- Prefer stateless widgets when possible
- Extract business logic out of UI widgets
- Avoid massive build methods
- Prefer composition over deeply nested widget trees
- Use clear naming and consistent file organization

## Refactoring Principles
- Do not rewrite the whole project at once
- Refactor incrementally and safely
- Preserve existing behavior unless explicitly asked to change it
- When changing structure, explain what changed and why
- Update imports carefully
- Reduce technical debt step by step

## Output Expectations
When making changes:
1. Explain the problem briefly
2. Propose a safe refactoring approach
3. Apply focused changes
4. Keep diffs reviewable
5. Mention any migration risks

## Testing / Validation
Before finalizing changes:
- Check for compile errors
- Check imports
- Check null safety issues
- Check deprecated API replacements
- Verify main user flows are not broken

## Important Constraints
- Do not introduce unnecessary packages
- Do not over-engineer
- Do not change app behavior unless requested
- Do not perform large-scale renaming without reason
- Do not break existing routing, localization, or persistence logic unless part of the task
