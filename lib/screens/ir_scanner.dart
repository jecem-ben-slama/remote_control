import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infrared_plugin/infrared_plugin.dart';

void main() => runApp(const MaterialApp(home: IrScannerScreen()));

// ── OPTIMIZED DATA ENCODING MODEL ───────────────────────────────
class IrScanCandidate {
  final int freq;
  final int addressByte;
  final int commandByte;

  const IrScanCandidate({
    required this.freq,
    required this.addressByte,
    required this.commandByte,
  });

  String get addrHex =>
      '0x${addressByte.toRadixString(16).toUpperCase().padLeft(2, '0')}';
  String get cmdHex =>
      '0x${commandByte.toRadixString(16).toUpperCase().padLeft(2, '0')}';
  String get label =>
      "${freq / 1000}kHz · Addr: $addrHex · Cmd: $cmdHex (Dec: $commandByte)";

  /// Dynamically computes precise microsecond timings for the NEC Protocol
  List<int> get pattern {
    // Lead Header: 9000µs Burst, 4500µs Space
    final List<int> timingPattern = [9000, 4500];

    // Encode 8-bit Address Byte and its Logical Inverse
    final int invertedAddress = (~addressByte) & 0xFF;
    _appendByteBits(timingPattern, addressByte);
    _appendByteBits(timingPattern, invertedAddress);

    // Encode 8-bit Command Byte and its Logical Inverse
    final int invertedCommand = (~commandByte) & 0xFF;
    _appendByteBits(timingPattern, commandByte);
    _appendByteBits(timingPattern, invertedCommand);

    // Burst Stop Line trailer
    timingPattern.addAll([560, 40000]);
    return timingPattern;
  }

  void _appendByteBits(List<int> bitStream, int byteValue) {
    for (int i = 0; i < 8; i++) {
      int bit = (byteValue >> i) & 1;
      if (bit == 1) {
        bitStream.addAll([560, 1690]); // Mark = 560µs, Space 1 = 1690µs
      } else {
        bitStream.addAll([560, 560]); // Mark = 560µs, Space 0 = 560µs
      }
    }
  }

  String get dartProfile =>
      '''
// Discovered Valid Response Token
// Frequency : $freq Hz
// Address   : $addrHex
// Command   : $cmdHex (Decimal: $commandByte)
List<int> get targetPattern => [${pattern.join(', ')}];
''';
}

// ── MAIN AUTOMATED SCANNER UI & CONTROLLER ──────────────────────
class IrScannerScreen extends StatefulWidget {
  const IrScannerScreen({super.key});

  @override
  State<IrScannerScreen> createState() => _IrScannerScreenState();
}

class _IrScannerScreenState extends State<IrScannerScreen> {
  final InfraredPlugin _irPlugin = InfraredPlugin();

  // Settings
  final int _targetAddress = 0x01; // Hardlocked to your working TV address
  int _selectedFrequency = 38000; // Default target carrier
  int _currentCommandIndex = 0; // Tracks current command (0 to 255)

  // Automation State Engine
  bool _isAutoScanning = false;
  Timer? _autoScanTimer;
  int _scanDelayMs =
      1200; // Time window between bursts (adjust if TV needs more recovery time)

  String _terminalLog =
      "Scanner Ready. Select carrier frequency and tap START SWEEP.";
  final List<String> _foundMatchesLog = [];

  final List<int> _availableFrequencies = [30000, 33000, 36000, 38000, 40000];

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    super.dispose();
  }

  /// Handles the physical native IR blast execution
  Future<void> _fireActiveSignal(IrScanCandidate candidate) async {
    try {
      await _irPlugin.transmitInts(
        frequency: candidate.freq,
        pattern: candidate.pattern,
      );
    } catch (error) {
      _haltAutoScan();
      setState(
        () => _terminalLog = "HARDWARE DISPATCH INTERRUPT FAULT:\n$error",
      );
    }
  }

  /// Starts the automated loop through all 256 registers
  void _startAutoScan() {
    if (_isAutoScanning) return;

    setState(() {
      _isAutoScanning = true;
      _terminalLog = "AUTOMATION ACTIVE: Beginning register sweep loop...";
    });

    _executeLoopStep();
  }

  void _executeLoopStep() {
    if (!_isAutoScanning) return;

    // Check if we reached the boundary condition (exhausted all 256 commands)
    if (_currentCommandIndex > 255) {
      _haltAutoScan();
      setState(() {
        _currentCommandIndex = 0;
        _terminalLog = "SUCCESS: Complete 256 command sweep loop finished.";
      });
      return;
    }

    final activeCandidate = IrScanCandidate(
      freq: _selectedFrequency,
      addressByte: _targetAddress,
      commandByte: _currentCommandIndex,
    );

    setState(() => _terminalLog = "BURSTING MATRIX: ${activeCandidate.label}");
    _fireActiveSignal(activeCandidate);

    // Schedule next increment step
    _autoScanTimer = Timer(Duration(milliseconds: _scanDelayMs), () {
      if (!mounted) return;
      setState(() => _currentCommandIndex++);
      _executeLoopStep();
    });
  }

  void _haltAutoScan() {
    _autoScanTimer?.cancel();
    setState(() {
      _isAutoScanning = false;
      _terminalLog =
          "Automation Paused. Standing down at Command Vector Index #$_currentCommandIndex.";
    });
  }

  void _resetScanProgression() {
    _haltAutoScan();
    setState(() {
      _currentCommandIndex = 0;
      _terminalLog = "Sweep buffer reset to Command 0x00.";
    });
  }

  void _bookmarkCurrentCommand() {
    final activeCandidate = IrScanCandidate(
      freq: _selectedFrequency,
      addressByte: _targetAddress,
      commandByte: _currentCommandIndex,
    );

    final logEntry =
        "[MATCH FOUND] Cmd ${_currentCommandIndex.toRadixString(16).toUpperCase().padLeft(2, '0')} (${_currentCommandIndex}) @ ${_selectedFrequency / 1000}kHz";

    setState(() {
      _foundMatchesLog.insert(0, logEntry);
      _terminalLog = "BOOKMARKED MATCH:\n${activeCandidate.label}";
    });

    debugPrint(activeCandidate.dartProfile);
  }

  @override
  Widget build(BuildContext context) {
    final currentCandidate = IrScanCandidate(
      freq: _selectedFrequency,
      addressByte: _targetAddress,
      commandByte: _currentCommandIndex.clamp(0, 255),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      appBar: AppBar(
        title: const Text(
          "SMASNUG Auto-Command Sweeper",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF131318),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Frequency Selection Track
            Text(
              "SELECT CARRIER MODULATION FREQUENCY",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableFrequencies.map((freq) {
                  final bool isSelected = _selectedFrequency == freq;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        "${freq / 1000} kHz",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.cyanAccent,
                      backgroundColor: const Color(0xFF1B1B22),
                      onSelected: _isAutoScanning
                          ? null
                          : (selected) {
                              if (selected)
                                setState(() => _selectedFrequency = freq);
                            },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Automation Tracking Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "COMMAND REGISTER SWEEP VECTOR",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "$_currentCommandIndex / 255 Commands",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _currentCommandIndex / 255,
              backgroundColor: Colors.white10,
              color: Colors.cyanAccent,
              minHeight: 8,
            ),
            const SizedBox(height: 24),

            // Visual Status Dashboard Shell
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isAutoScanning
                        ? Colors.cyanAccent.withOpacity(0.3)
                        : Colors.white12,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isAutoScanning
                          ? Icons.sync_rounded
                          : Icons.radio_button_off_rounded,
                      size: 48,
                      color: _isAutoScanning ? Colors.cyanAccent : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentCandidate.cmdHex,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Target Address: ${currentCandidate.addrHex}  ·  Freq: ${currentCandidate.freq / 1000}kHz",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Realtime Output Logging Screen Terminal
            Container(
              height: 75,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _terminalLog,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.greenAccent,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Found Matches List Window Display
            Text(
              "MARKED MATCH RECOVERY INDEX",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF18181F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: _foundMatchesLog.isEmpty
                    ? const Center(
                        child: Text(
                          "No matches flagged yet. Tap 'MARK MATCH' when TV reacts.",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _foundMatchesLog.length,
                        itemBuilder: (context, idx) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          child: Text(
                            _foundMatchesLog[idx],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Automation Control Grid Buttons Interface
            Row(
              children: [
                Expanded(
                  child: _CtrlButton(
                    label: "RESET",
                    color: Colors.orangeAccent,
                    onTap: _resetScanProgression,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _CtrlButton(
                    label: _isAutoScanning ? "PAUSE SWEEP" : "START AUTO SWEEP",
                    color: _isAutoScanning
                        ? Colors.redAccent
                        : Colors.cyanAccent,
                    onTap: _isAutoScanning ? _haltAutoScan : _startAutoScan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _bookmarkCurrentCommand,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text("MARK MATCH (SAVE CODE)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF142416),
                foregroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CUSTOM UTILITY INTERACTION BUTTON CONTROLLER ────────────────
class _CtrlButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CtrlButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4), width: 1.2),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
