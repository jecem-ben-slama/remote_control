# Developer Quick Start Guide

## 🎯 Quick Navigation

### Finding Code by Feature

| Feature                       | File(s)                                       |
| ----------------------------- | --------------------------------------------- |
| IR command data model         | `lib/models/ir_command.dart`                  |
| IR transmission logic         | `lib/services/native_ir_blaster_service.dart` |
| IR interface (mockable)       | `lib/services/ir_blaster_service.dart`        |
| Command collection management | `lib/repositories/ir_command_repository.dart` |
| App state & status            | `lib/providers/ir_state_provider.dart`        |
| Command editor screen         | `lib/screens/command_mapper_screen.dart`      |
| Remote control UI             | `lib/screens/mini_remote_screen.dart`         |
| Remote button widget          | `lib/widgets/remote_button.dart`              |
| Command list widget           | `lib/widgets/command_registry_list.dart`      |
| PDF export                    | `lib/services/pdf_export_service.dart`        |
| Protocol constants            | `lib/constants/ir_constants.dart`             |

## 🔧 Common Tasks

### Change IR Protocol Address

```dart
// lib/constants/ir_constants.dart
static const int deviceAddress = 0x01; // Change this
```

### Change Carrier Frequency

```dart
// lib/constants/ir_constants.dart
static const int carrierFrequencyHz = 38000; // Change to 36000, 40000, etc.
```

### Add New Pre-configured Command

```dart
// lib/repositories/ir_command_repository.dart
const Map<int, String> seedData = {
  14: 'Volume Up',
  // Add new mapping here
  99: 'Your New Command',
};
```

### Customize Remote Button

```dart
// lib/widgets/remote_button.dart
// Modify colors, sizing, animation in RemoteButton widget
const Color(0xFF00C853) // Change this color
```

### Change IR Transmission Error Handling

```dart
// lib/providers/ir_state_provider.dart
try {
  await _irBlaster.transmitSignal(commandCode);
  _updateStatus('✓ Dispatched $hexStr successfully');
} catch (e) {
  _updateStatus('✗ Transmission failed: ${e.toString()}'); // Custom error message
}
```

### Add Persistence for Command Labels

```dart
// lib/repositories/ir_command_repository.dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveToPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  // Save logic
}
```

### Test IR Encoding Without Hardware

```dart
// Create a test file
import 'package:test/test.dart';
import 'lib/services/native_ir_blaster_service.dart';

void main() {
  test('NEC protocol encoding', () {
    final service = NativeIrBlasterService();
    final pattern = service._encodeNecSignal(0x0E); // Access private method for testing
    expect(pattern.length, greaterThan(0));
    expect(pattern.first, equals(9000)); // Header mark
  });
}
```

## 📊 State Management Flow

```
User clicks Remote Button
  ↓
RemoteButton.onPressed()
  ↓
IRStateProvider.transmitCommand(commandCode)
  ↓
IIrBlasterService.transmitSignal(commandCode)
  ↓
NativeIrBlasterService encodes NEC protocol
  ↓
InfraredPlugin.transmitInts() sends to hardware
  ↓
IRStateProvider updates status
  ↓
UI rebuilds with Consumer<IRStateProvider>
```

## 🧪 Testing Strategy

### Unit Tests

- Test `NativeIrBlasterService._encodeNecSignal()` with known command codes
- Test `IRCommandRepository` methods without UI
- Test `IRConstants` values for correctness

### Widget Tests

- Test `RemoteButton` with simulated taps
- Test `CommandRegistryList` with sample command list
- Test `CommandMapperScreen` with mocked provider

### Integration Tests

- Mock `IIrBlasterService` to test full flow
- Test Provider state transitions
- Verify error messages appear on failures

### Golden Tests

- Snapshot test remote button appearance
- Snapshot test command mapper layout

## 🐛 Debugging Tips

### Enable verbose logging

```dart
// In providers/ir_state_provider.dart
Future<void> transmitCommand(int commandCode) async {
  print('DEBUG: Transmitting command $commandCode');
  // ... rest of code
}
```

### Mock IR service for testing

```dart
class MockIrBlaster implements IIrBlasterService {
  @override
  Future<void> transmitSignal(int commandByte) async {
    print('MOCK: Would transmit $commandByte');
    await Future.delayed(Duration(milliseconds: 500));
  }
}

// In test or debug mode:
// provider = IRStateProvider(irBlaster: MockIrBlaster(), repository: repo);
```

### Check NEC pattern generation

```dart
import 'lib/services/native_ir_blaster_service.dart';

void debugNecPattern(int command) {
  final service = NativeIrBlasterService();
  final pattern = service._encodeNecSignal(command);
  print('Pattern for 0x${command.toRadixString(16)}: $pattern');
  print('Header: ${pattern[0]}, ${pattern[1]}');
  print('Total timing: ${pattern.reduce((a, b) => a + b)} µs');
}
```

## 📈 Performance Considerations

1. **ListView optimization**: `CommandRegistryList` uses `itemExtent: 52` to avoid layout calculations
2. **Provider rebuilds**: Use `Consumer` only on widgets that need state
3. **Animation performance**: `RemoteButton` uses single `AnimationController` (not repeated)
4. **Memory**: Proper `dispose()` in all stateful components and services

## 🔐 Security Notes

1. No sensitive data stored in code (no API keys, tokens)
2. IR commands are fixed address (0x01) - hardware-specific
3. Exception messages don't leak internal details to user
4. All external inputs (command codes) validated against range [0-255]

## 📚 Architecture Decision Records

### Why Provider instead of Riverpod/GetX?

- Minimal, easy to understand
- Built on Flutter best practices (ChangeNotifier)
- Easy to test with mocks
- No code generation needed

### Why Repository pattern?

- Decouples data access from business logic
- Easy to swap implementation (Hive, Firestore, etc.)
- Single source of truth for command list
- Simplifies testing

### Why NEC protocol constants?

- All timing values in one place
- Easy to experiment with different frequencies
- Clear documentation of protocol structure
- No magic numbers scattered in code

## 🚀 Extending the App

### Add Support for Learning Mode

1. Create `lib/services/ir_learner_service.dart` with `IIrLearnerService` interface
2. Extend `IRStateProvider` with `learnCommand(index)` method
3. Add UI for entering learn mode
4. Save learned commands to repository

### Add Schedule/Timer Feature

1. Add `scheduledCommands: List<ScheduledCommand>` to `IRStateProvider`
2. Create `Timer` management in state provider
3. Add schedule UI screen
4. Use platform channels for background execution

### Add Command Shortcuts

1. Add `hotkeys: Map<String, int>` to `IRStateProvider`
2. Listen for keyboard events in `MainNavigationShell`
3. Map keyboard keys to command codes
4. Add shortcut configuration UI

---

**Last Updated**: After major refactoring (13 focused files)
**Version**: 1.0.0
**Flutter SDK**: ^3.10.7
