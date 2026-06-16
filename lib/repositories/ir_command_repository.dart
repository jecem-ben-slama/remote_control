import '../models/ir_command.dart';

/// Repository for managing IR commands
/// Encapsulates all command-related data access and manipulation logic
class IRCommandRepository {
  static const int _totalCommands = 256;
  final List<IRCommand> commands = _initializeCommands();

  /// Retrieves command by index
  IRCommand getCommand(int index) {
    if (index < 0 || index >= commands.length) {
      throw RangeError('Command index out of range: $index');
    }
    return commands[index];
  }

  /// Gets count of labeled commands
  int getLabeledCommandCount() {
    return commands.where((cmd) => cmd.hasLabel).length;
  }

  /// Gets all labeled commands
  List<IRCommand> getLabeledCommands() {
    return commands.where((cmd) => cmd.hasLabel).toList();
  }

  /// Updates a command's label
  void updateCommandLabel(int index, String label) {
    final command = getCommand(index);
    command.controller.text = label;
  }

  /// Clears all command labels
  void clearAllLabels() {
    for (var command in commands) {
      command.controller.clear();
    }
  }

  /// Disposes all resources
  void dispose() {
    for (var command in commands) {
      command.dispose();
    }
  }

  /// Initializes commands with seed data
  static List<IRCommand> _initializeCommands() {
    final List<IRCommand> cmds = List.generate(
      _totalCommands,
      (i) => IRCommand(i),
    );

    // Pre-populate known command mappings
    const Map<int, String> seedData = {
      14: 'Volume Up',
      15: 'Volume Down',
      16: 'Power Off',
      17: 'Source Select',
      21: 'Menu',
      23: 'Mute',
      24: 'D-Pad Up',
      26: 'D-Pad Down',
      27: 'D-Pad Left',
      28: 'D-Pad Right',
      29: 'Enter / OK',
      67: 'Back / Return',
    };

    for (var entry in seedData.entries) {
      cmds[entry.key].controller.text = entry.value;
    }

    return cmds;
  }
}
