# Project Context

This Flutter project was originally created several years ago and may contain:
- outdated Flutter patterns
- large widget files
- mixed UI and business logic
- older package usage
- inconsistent folder structure

## Refactoring Strategy
This project should be modernized gradually.

Priority order:
1. Fix deprecated APIs
2. Improve code safety and null safety
3. Separate UI and logic
4. Refactor large widgets into smaller reusable widgets
5. Introduce a cleaner feature-based structure
6. Improve maintainability without breaking existing behavior

## Preferred Technical Direction
- Flutter modern conventions
- Dart null safety
- Riverpod for state management
- Repository pattern for data access
- MVVM or Clean Architecture style separation

## Important Notes
- Stability is more important than aggressive rewriting
- Small safe changes are preferred over broad rewrites
- Existing user flows should remain working
- Avoid unnecessary dependency additions
