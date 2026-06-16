import 'package:flutter/material.dart';
import '../models/ir_command.dart';
import '../repositories/ir_command_repository.dart';
import '../services/ir_blaster_service.dart';

/// State provider for IR command and hardware operations
/// Uses ChangeNotifier for reactive state management
/// Follows Single Responsibility Principle - only manages IR state
class IRStateProvider extends ChangeNotifier {
  final IIrBlasterService _irBlaster;
  final IRCommandRepository _repository;

  int? _selectedCommandIndex;
  String _hardwareStatus = 'Ready';
  bool _isTransmitting = false;

  IRStateProvider({
    required IIrBlasterService irBlaster,
    required IRCommandRepository repository,
  }) : _irBlaster = irBlaster,
       _repository = repository;

  // Getters
  int? get selectedCommandIndex => _selectedCommandIndex;
  String get hardwareStatus => _hardwareStatus;
  bool get isTransmitting => _isTransmitting;
  List<IRCommand> get commands => _repository.commands;
  int get labeledCommandCount => _repository.getLabeledCommandCount();

  /// Selects a command by index
  void selectCommand(int index) {
    _selectedCommandIndex = index;
    notifyListeners();
  }

  /// Updates hardware status message
  void _updateStatus(String message) {
    _hardwareStatus = message;
    notifyListeners();
  }

  /// Transmits an IR signal for the specified command
  Future<void> transmitCommand(int commandCode) async {
    if (_isTransmitting) return;

    _isTransmitting = true;
    final hexStr = _repository.getCommand(commandCode).hex;

    try {
      _updateStatus('Transmitting $hexStr...');
      await _irBlaster.transmitSignal(commandCode);
      _updateStatus('✓ Dispatched $hexStr successfully');
    } catch (e) {
      _updateStatus('✗ Transmission failed: ${e.toString()}');
    } finally {
      _isTransmitting = false;
      notifyListeners();
    }
  }

  /// Updates a command label
  void updateCommandLabel(int index, String label) {
    _repository.updateCommandLabel(index, label);
    notifyListeners();
  }

  /// Clears all command labels
  void clearAllLabels() {
    _repository.clearAllLabels();
    notifyListeners();
  }

  /// Gets labeled commands for export
  List<IRCommand> getLabeledCommands() {
    return _repository.getLabeledCommands();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
