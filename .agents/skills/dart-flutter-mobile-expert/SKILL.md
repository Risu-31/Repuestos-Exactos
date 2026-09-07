---
name: dart-flutter-mobile-expert
description: Use this skill whenever writing, modifying, or architecting Dart and Flutter code, mobile apps, REST/WebSocket API integrations, and Bluetooth/BLE communication.
---

# Dart & Flutter Mobile Expert Skill

This skill guides the agent in writing production-grade, highly performant Dart and Flutter applications for mobile devices (Android & iOS).

## Core Principles & Dart Best Practices

1. **Modern Dart Syntax**:
   - Use null-safety strictly; avoid unnecessary bang (`!`) operators by properly handling optional states.
   - Leverage pattern matching, switch expressions, and records where appropriate.
   - Use `final` and `const` constructors wherever possible to maximize widget rebuild performance.

2. **State Management & Flutter Lifecycle**:
   - Keep widgets dumb and business logic decoupled (use BLoC, Riverpod, or lightweight ValueNotifiers/ChangeNotifiers depending on project standard).
   - Never place side-effects (API calls, Bluetooth scanning) directly inside `build()` methods.
   - Always dispose controllers (`AnimationController`, `TextEditingController`, `StreamSubscription`) in `dispose()`.

## API Integrations (REST & WebSockets)

1. **Robust Networking**:
   - Encapsulate HTTP requests inside dedicated client/service classes.
   - Always catch specific network errors (`SocketException`, `HttpException`, timeout errors) and map them to clean domain failure objects.
   - Implement interceptors or wrapper functions for auth tokens, request logging, and unified error handling.
2. **Serialization**:
   - Use type-safe serialization methods (`fromJson`, `toJson`) or code generation (`freezed`, `json_serializable`).
   - Validate response payloads before parsing to avoid unhandled runtime type cast exceptions.

## Bluetooth & BLE (Bluetooth Low Energy)

1. **Lifecycle & Permissions**:
   - Verify and request platform permissions before initializing adapters:
     - Android: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION` (for older Android versions).
     - iOS: `NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`.
   - Always check adapter power state (On, Off, Unauthorized, Unsupported) before scanning.
2. **Scan & Connection Management**:
   - Provide explicit scan timeouts to conserve battery.
   - Implement exponential backoff or user-controlled retry mechanisms on connection drops.
   - Listen to device connection state streams and reflect connection drops immediately in the UI.
3. **GATT Services & Characteristics**:
   - Cache discovered services and characteristics when appropriate.
   - Handle MTU size negotiation when transmitting large byte buffers.
   - Ensure streams for notifications/indications are properly unsubscribed when closing views or disconnecting.
