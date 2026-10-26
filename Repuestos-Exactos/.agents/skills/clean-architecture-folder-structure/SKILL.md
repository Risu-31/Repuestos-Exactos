---
name: clean-architecture-folder-structure
description: Use this skill whenever structuring folders, organizing files, deciding where business logic vs UI vs data access belongs, or refactoring project architecture.
---

# Clean Architecture & Folder Structure Skill

This skill guides the agent to enforce strict separation of concerns and maintain a clean, predictable, and scalable folder organization.

## Architectural Separation of Concerns

Every component must live where it belongs:
- **Presentation (UI)**: Screens, widgets, dialogs, visual formatters, and local UI state. Never put raw SQL, direct HTTP requests, or hardware communication inside UI code.
- **Application / Logic**: Controllers, BLoCs, cubits, notifiers, use-cases. Orchestrates data flows and state transitions.
- **Domain**: Business models, entities, repository interfaces, validation rules. Independent of third-party frameworks.
- **Data / Infrastructure**: Concrete repository implementations, API clients, local databases (SQLite/Hive/Isar/Prefs), Bluetooth drivers, and external device adapters.

## Standard Feature-First Folder Structure

Organize code by feature or domain module to maintain high cohesion:

```text
lib/
├── core/                         # Cross-cutting utilities shared by all features
│   ├── constants/                # App strings, assets, dimensions
│   ├── network/                  # HTTP clients, interceptors, error parsers
│   ├── theme/                    # Color schemes, typography, styles
│   └── utils/                    # Generic helpers, formatters, extensions
│
├── features/                     # Functional modules of the app
│   └── <feature_name>/           # e.g., auth, bluetooth_scanner, diagnostics
│       ├── data/                 # Data layer
│       │   ├── datasources/      # Remote (API) & Local (DB/Hardware) data sources
│       │   ├── models/           # DTOs, JSON serialization, hardware byte mappers
│       │   └── repositories/     # Concrete repository implementations
│       ├── domain/               # Business rules & abstract contracts
│       │   ├── entities/         # Pure domain entities
│       │   └── repositories/     # Repository interfaces/contracts
│       └── presentation/         # UI layer
│           ├── controllers/      # State management (BLoC, Riverpod, Notifiers)
│           ├── views/            # Full-page screens
│           └── widgets/          # Feature-specific reusable UI components
│
└── main.dart                     # App entry point, dependency injection setup
```

## Golden Rules of Organization

1. **Unidirectional Dependency Flow**:
   - Presentation depends on Domain (via interfaces or state controllers).
   - Data implements Domain interfaces.
   - Domain depends on NOTHING external.
2. **Single Responsibility per File**:
   - One primary class or widget per file.
   - Separate models (`.dart`), state controllers (`_controller.dart`), screens (`_screen.dart`), and sub-widgets (`_card.dart`, `_tile.dart`).
3. **Keep It Simple & Functional**:
   - Avoid creating 10 layers of abstraction for a simple 1-line query.
   - Structure folders logically so any developer can locate where code belongs in under 3 seconds.
