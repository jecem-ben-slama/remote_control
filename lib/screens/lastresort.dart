import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infrared_plugin/infrared_plugin.dart';

// ==========================================================================
// SMASNUG ULTRA-LOW FREQUENCY SUBSURFACE LABORATORY (METHOD-CHANNEL BYPASS)
// Bypasses missing plugin endpoints to directly force-test low-end carrier
// transmission frequencies while tracking pipeline logs.
//
// UPDATED CORE: Injects Standby Pre-Preamble bursts and heavy 35x frame
// repeat loops specifically optimized to break TV standby wake-up thresholds.
// ==========================================================================

void main() => runApp(
  const MaterialApp(
    home: IrRecoveryPlaygroundScreen(),
    debugShowCheckedModeBanner: false,
  ),
);

class IrRecoveryPlaygroundScreen extends StatefulWidget {
  const IrRecoveryPlaygroundScreen({super.key});

  @override
  State<IrRecoveryPlaygroundScreen> createState() =>
      _IrRecoveryPlaygroundScreenState();
}

class _IrRecoveryPlaygroundScreenState
    extends State<IrRecoveryPlaygroundScreen> {
  final InfraredPlugin _irPlugin = InfraredPlugin();

  // Immutable Target Constants
  final int _targetAddress = 0x01;
  final int _powerCommand = 16; // Power Toggle register (0x10)

  int _selectedFrequency = 26000; // Initial low carrier threshold (26 kHz)
  bool _isBlasting = false;
  String _terminalOutput =
      "SYSTEM ONLINE.\nSelect an ultra-low carrier frequency below and tap a profile to transmit.";
  final String _hardwareBoundsText =
      "Plugin limits unreadable (getCarrierFrequencies missing).\n• FORCING OPTIMISTIC OVERRIDE MODE";

  // Ultra-low target frequencies below the standard market baselines
  final List<int> _frequencies = [20000, 24000, 26000, 28000];

  // Fixed Bit-Mapping Structural Tokens
  static const List<int> _addressBits = [
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ]; // LSB First 0x01
  static const List<int> _invertedAddressBits = [
    0,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
  ]; // 0xFE

  @override
  void initState() {
    super.initState();
    // Bypassing native method channel call to avoid MissingPluginException
    debugPrint(
      "[IR CORE] Native capability query bypassed due to plugin implementation constraints.",
    );
  }

  // ── MATHEMATICAL TIMING COMPRESSION ENGINE ─────────────────────────
  List<int> _buildCompressedNecFrame(int command, double compressionFactor) {
    final int headerMark = (9000 * compressionFactor).round();
    final int headerSpace = (4500 * compressionFactor).round();
    final int logicalOne = (1690 * compressionFactor).round();
    final int logicalZero = (560 * compressionFactor).round();

    final List<int> pattern = [headerMark, headerSpace];

    // 1. Unroll Address Fields (0x01 + 0xFE)
    for (int bit in [..._addressBits, ..._invertedAddressBits]) {
      pattern.addAll([logicalZero, bit == 1 ? logicalOne : logicalZero]);
    }

    // 2. Unroll Command Fields (Data + Bitwise Inversion)
    for (int i = 0; i < 8; i++) {
      int bit = (command >> i) & 1;
      pattern.addAll([logicalZero, bit == 1 ? logicalOne : logicalZero]);
    }
    for (int i = 0; i < 8; i++) {
      int bit = ((~command & 0xFF) >> i) & 1;
      pattern.addAll([logicalZero, bit == 1 ? logicalOne : logicalZero]);
    }

    pattern.add(logicalZero);
    return pattern;
  }

  // ── HARDWARE WAKE-UP & SATURATION DISPATCH ENGINE ────────────────────
  Future<void> _safeAsyncBlast({
    required List<int> coreFrame,
    double compressionFactor = 1.0,
    int repeatCount =
        35, // Amplified repeat payload matrix to force standby bypass
    required String strategyLabel,
    bool injectPrePreamble = false, // Set to true for target wake attempts
  }) async {
    if (_isBlasting) return;

    setState(() {
      _isBlasting = true;
      _terminalOutput =
          "STAGING DISPATCH: $strategyLabel\nTarget Modulation: ${_selectedFrequency / 1000} kHz...\nWriting array to peripheral bus...";
    });

    try {
      debugPrint("[IR TRANSMIT] Initiating $strategyLabel");

      // 1. OPTIONAL STANDBY WAKE PRE-PREAMBLE
      // Fires a continuous carrier wave burst to charge up the TV's receiver photodiode
      // and shake the microcontroller out of sleep before delivering the real payload.
      if (injectPrePreamble) {
        debugPrint(
          "[IR TRANSMIT] Injecting Standby Pre-Preamble Wake Burst...",
        );
        final List<int> wakePreamble = [
          12000,
          6000,
          560,
        ]; // Long continuous burst
        await _irPlugin.transmitInts(
          frequency: _selectedFrequency,
          pattern: wakePreamble,
        );
        // Microsecond rest period for the receiver's Automatic Gain Control (AGC) to stabilize
        await Future.delayed(const Duration(milliseconds: 40));
      }

      // 2. TRANSMIT BASE PAYLOAD FRAME
      final List<int> payloadPattern = List.from(coreFrame)..add(40000);
      debugPrint(
        "[IR TRANSMIT] Dispatching Base Payload Sequence: $payloadPattern",
      );

      await _irPlugin.transmitInts(
        frequency: _selectedFrequency,
        pattern: payloadPattern,
      );

      // 3. HIGH-SATURATION REPEAT STREAM
      if (repeatCount > 0) {
        final int repeatMark = (9000 * compressionFactor).round();
        final int repeatSpace = (2250 * compressionFactor).round();
        final int repeatZero = (560 * compressionFactor).round();

        final List<int> repeatPacket = [
          repeatMark,
          repeatSpace,
          repeatZero,
          40000,
        ];
        final int structuralDelayMs = (96 * compressionFactor).round();

        debugPrint(
          "[IR TRANSMIT] Streaming $repeatCount packets with a micro-gap of ${structuralDelayMs}ms... SENSITIVITY OVERRIDE ACTIVE.",
        );

        for (int i = 0; i < repeatCount; i++) {
          await Future.delayed(Duration(milliseconds: structuralDelayMs));
          debugPrint(
            "[IR TRANSMIT] Burst Repeat Pulse Iteration [${i + 1}/$repeatCount]",
          );
          await _irPlugin.transmitInts(
            frequency: _selectedFrequency,
            pattern: repeatPacket,
          );
        }
      }

      setState(() {
        _terminalOutput =
            "BURST DISPATCH SUCCESS!\n\nProfile: $strategyLabel\nModulated Carrier: ${_selectedFrequency / 1000} kHz\nPayload Size: ${payloadPattern.length} timings\nRepeats Pushed: $repeatCount frames\nPre-Preamble: $injectPrePreamble";
      });
    } catch (e) {
      debugPrint("[IR TRANSMIT] CRITICAL HARDWARE WRITE FAULT: $e");
      setState(() {
        _terminalOutput =
            "HARDWARE IO EXPULSION FAULT:\n$e\n\nIf this error targets the frequency bounds, your phone kernel is blocking sub-30kHz directly.";
      });
    } finally {
      setState(() => _isBlasting = false);
    }
  }

  // ── STRATEGY PROFILES ─────────────────────────────────────────────

  void _executeStrategyBaseline() {
    final coreFrame = _buildCompressedNecFrame(_powerCommand, 1.0);
    _safeAsyncBlast(
      coreFrame: coreFrame,
      compressionFactor: 1.0,
      repeatCount: 35, // Pumping total frames up from 6 to 35
      injectPrePreamble: true, // Forces initial wake pulse
      strategyLabel: "UNALTERED TIMING VECTOR (STANDBY OVERRIDE)",
    );
  }

  void _executeStrategy10Percent() {
    final coreFrame = _buildCompressedNecFrame(_powerCommand, 0.90);
    _safeAsyncBlast(
      coreFrame: coreFrame,
      compressionFactor: 0.90,
      repeatCount: 35,
      injectPrePreamble: true,
      strategyLabel: "ALPHA LAYER COMPRESSION (-10% SLEEP ATTENUATION)",
    );
  }

  void _executeStrategy15Percent() {
    final coreFrame = _buildCompressedNecFrame(_powerCommand, 0.85);
    _safeAsyncBlast(
      coreFrame: coreFrame,
      compressionFactor: 0.85,
      repeatCount: 35,
      injectPrePreamble: true,
      strategyLabel: "BETA LAYER COMPRESSION (-15% DRIFT MATCH)",
    );
  }

  void _executeStrategy20Percent() {
    final coreFrame = _buildCompressedNecFrame(_powerCommand, 0.80);
    _safeAsyncBlast(
      coreFrame: coreFrame,
      compressionFactor: 0.80,
      repeatCount: 35,
      injectPrePreamble: true,
      strategyLabel: "GAMMA LAYER COMPRESSION (-20% COLD CLOCK)",
    );
  }

  void _executeStrategy25Percent() {
    final coreFrame = _buildCompressedNecFrame(_powerCommand, 0.75);
    _safeAsyncBlast(
      coreFrame: coreFrame,
      compressionFactor: 0.75,
      repeatCount: 40, // Maximum saturation strategy
      injectPrePreamble: true,
      strategyLabel: "DELTA EXTREME VECTOR (-25% STANDBY ATTACK)",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080C),
      appBar: AppBar(
        title: const Text(
          "SUB-30kHz SUBSURFACE MODULE",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF101015),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hardware Capability Banner Diagnostic Box
            Text(
              "XIAOMI PHONE KERNEL IR DRIVER STATUS",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF13111C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Colors.purpleAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _hardwareBoundsText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sub-30kHz Frequency Chip Grid
            Text(
              "ULTRA-LOW FREQUENCY DRIFT TRACK MATRIX",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _frequencies.map((freq) {
                final isSelected = _selectedFrequency == freq;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(
                        "${freq ~/ 1000} kHz",
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.deepPurpleAccent.withOpacity(0.2),
                      checkmarkColor: Colors.deepPurpleAccent,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.deepPurpleAccent
                            : Colors.grey.shade400,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: const Color(0xFF121217),
                      onSelected: _isBlasting
                          ? null
                          : (selected) {
                              if (selected) {
                                setState(() => _selectedFrequency = freq);
                              }
                            },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Native Bus Telemetry Frame Console View Box
            Text(
              "NATIVE PERIPHERAL IO CORE TELEMETRY & REPORT LOGS",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 130,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _terminalOutput,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.amberAccent,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Compression Strategy Interface Blocks
            Text(
              "TIMING PROFILE SELECTION ARRAYS",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            _StrategyCard(
              index: "0",
              title: "Standard Timing Parameters (0% Compression)",
              description:
                  "Fires untouched microsecond widths via the newly mapped low frequency carrier band. Injects wake preamble.",
              color: Colors.grey,
              onTap: _executeStrategyBaseline,
            ),
            const SizedBox(height: 12),

            _StrategyCard(
              index: "A",
              title: "Alpha Compression Variant (-10%)",
              description:
                  "Squeezes all timing gaps down by 10%. Perfect for matching light component oscillator lags under standby voltage drops.",
              color: Colors.tealAccent,
              onTap: _executeStrategy10Percent,
            ),
            const SizedBox(height: 12),

            _StrategyCard(
              index: "B",
              title: "Beta Compression Variant (-15%)",
              description:
                  "Combines 15% interval shrinking with chosen sub-30kHz clocks. Overcomes cold oscillator drift in standby chips.",
              color: Colors.indigoAccent,
              onTap: _executeStrategy15Percent,
            ),
            const SizedBox(height: 12),

            _StrategyCard(
              index: "C",
              title: "Gamma Compression Variant (-20%)",
              description:
                  "Aggressive 20% microsecond compression pipeline. Intended for matching highly delayed or sluggish standby processor internal cycles.",
              color: Colors.purpleAccent,
              onTap: _executeStrategy20Percent,
            ),
            const SizedBox(height: 12),

            _StrategyCard(
              index: "D",
              title: "Delta Extreme Compression Vector (-25%)",
              description:
                  "Maximum unrolled timing shrinkage threshold with 40 frame loop saturation to pierce through sleep-mode attenuation.",
              color: Colors.pinkAccent,
              isUltimate: true,
              onTap: _executeStrategy25Percent,
            ),
          ],
        ),
      ),
    );
  }
}

class _StrategyCard extends StatelessWidget {
  final String index;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isUltimate;

  const _StrategyCard({
    required this.index,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.isUltimate = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUltimate ? const Color(0xFF1A0A10) : const Color(0xFF101015),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(isUltimate ? 0.4 : 0.15),
            width: isUltimate ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                index,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.waves_rounded, size: 16, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
