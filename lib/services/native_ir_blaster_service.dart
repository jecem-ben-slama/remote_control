/* import 'package:infrared_plugin/infrared_plugin.dart';
import 'ir_blaster_service.dart';

/// Native implementation of IR blaster service using the infrared_plugin
/// Encodes IR signals using NEC protocol with 38kHz carrier frequency
class NativeIrBlasterService implements IIrBlasterService {
  final InfraredPlugin _irPlugin = InfraredPlugin();

  // NEC Protocol configuration
  static const int _carrierFrequency = 38000;
  static const int _headerMark = 9000;
  static const int _headerSpace = 4500;
  static const int _logicalOne = 1690;
  static const int _logicalZero = 560;
  static const int _burstStop = 40000;

  // Fixed NEC address bits for this device
  static const List<int> _addressBits = [1, 0, 0, 0, 0, 0, 0, 0]; // 0x01
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
  Future<void> transmitSignal(int commandByte) async {
    try {
      final pattern = _encodeNecSignal(commandByte);
      await _irPlugin.transmitInts(
        frequency: _carrierFrequency,
        pattern: pattern,
      );
    } catch (e) {
      throw IrBlasterException(
        'Failed to transmit IR signal for command: 0x${commandByte.toRadixString(16)}',
        e,
      );
    }
  }

  /// Encodes a command byte into NEC protocol IR signal timing pattern
  ///
  /// NEC protocol structure:
  /// [Header][Address bits][Inverted address bits][Command bits][Inverted command bits][Stop]
  List<int> _encodeNecSignal(int commandByte) {
    // Decode command into individual bits (LSB first)
    final List<int> commandBits = _byteToBits(commandByte);
    final List<int> invertedCommandBits = _invertBits(commandBits);

    // Build timing pattern
    final List<int> pattern = [_headerMark, _headerSpace];

    // Encode address bits
    for (int bit in [..._addressBits, ..._invertedAddressBits]) {
      pattern.addAll(_encodeBit(bit));
    }

    // Encode command bits
    for (int bit in [...commandBits, ...invertedCommandBits]) {
      pattern.addAll(_encodeBit(bit));
    }

    // Add burst stop line
    pattern.addAll([_logicalZero, _burstStop]);

    return pattern;
  }

  /// Converts a byte to a list of bits (LSB first)
  List<int> _byteToBits(int byte) {
    final List<int> bits = [];
    for (int i = 0; i < 8; i++) {
      bits.add((byte >> i) & 1);
    }
    return bits;
  }

  /// Inverts a list of bits
  List<int> _invertBits(List<int> bits) {
    return bits.map((bit) => bit == 1 ? 0 : 1).toList();
  }

  /// Encodes a single bit as [mark, space] timing pair
  List<int> _encodeBit(int bit) {
    return [_logicalZero, bit == 1 ? _logicalOne : _logicalZero];
  }
}
 */
import 'package:infrared_plugin/infrared_plugin.dart';
import 'ir_blaster_service.dart';

/// Native implementation of IR blaster service using the infrared_plugin
/// Encodes IR signals using NEC protocol with 38kHz carrier frequency
class NativeIrBlasterService implements IIrBlasterService {
  final InfraredPlugin _irPlugin = InfraredPlugin();

  // NEC Protocol configuration
  static const int _carrierFrequency = 38000;
  static const int _headerMark = 9000;
  static const int _headerSpace = 4500;
  static const int _logicalOne = 1690;
  static const int _logicalZero = 560;
  static const int _burstStop = 40000;

  // Fixed NEC address bits for this device (0x01) - Read LSB-first
  static const List<int> _addressBits = [1, 0, 0, 0, 0, 0, 0, 0]; // 0x01
  
  // Inverted NEC address bits (0xFE) - Read LSB-first
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
  Future<void> transmitSignal(int commandByte) async {
    try {
      final pattern = _encodeNecSignal(commandByte);

      // Command 16 (0x10) is POWER.
      if (commandByte == 16) {
        // To turn a sleeping TV ON, we must keep sending bursts over a 350ms window.
        // This gives Android's hardware time to process between bursts without crashing.
        final stopwatch = Stopwatch()..start();
        
        await Future.doWhile(() async {
          await _irPlugin.transmitInts(
            frequency: _carrierFrequency,
            pattern: pattern,
          );
          
          // CRITICAL: A 65ms gap allows Android's IR queue to clear, 
          // while maintaining the strict NEC frame spacing requirement (~110ms total cycle).
          await Future.delayed(const Duration(milliseconds: 65));
          
          // Stop looping once we hit our target 350ms hold time
          return stopwatch.elapsedMilliseconds < 350;
        });
        
        stopwatch.stop();
      } else {
        // For all other buttons (Volume, Source, D-Pad), fire exactly once.
        await _irPlugin.transmitInts(
          frequency: _carrierFrequency,
          pattern: pattern,
        );
      }
    } catch (e) {
      throw IrBlasterException(
        'Failed to transmit IR signal for command: 0x${commandByte.toRadixString(16)}',
        e,
      );
    }
  }

  /// Encodes a command byte into NEC protocol IR signal timing pattern
  ///
  /// NEC protocol structure:
  /// [Header][Address bits][Inverted address bits][Command bits][Inverted command bits][Stop]
  List<int> _encodeNecSignal(int commandByte) {
    // Decode command into individual bits (LSB first)
    final List<int> commandBits = _byteToBits(commandByte);
    final List<int> invertedCommandBits = _invertBits(commandBits);

    // Build timing pattern
    final List<int> pattern = [_headerMark, _headerSpace];

    // Encode address bits
    for (int bit in [..._addressBits, ..._invertedAddressBits]) {
      pattern.addAll(_encodeBit(bit));
    }

    // Encode command bits
    for (int bit in [...commandBits, ...invertedCommandBits]) {
      pattern.addAll(_encodeBit(bit));
    }

    // Add burst stop line
    pattern.addAll([_logicalZero, _burstStop]);

    return pattern;
  }

  /// Converts a byte to a list of bits (LSB first)
  List<int> _byteToBits(int byte) {
    final List<int> bits = [];
    for (int i = 0; i < 8; i++) {
      bits.add((byte >> i) & 1);
    }
    return bits;
  }

  /// Inverts a list of bits
  List<int> _invertBits(List<int> bits) {
    return bits.map((bit) => bit == 1 ? 0 : 1).toList();
  }

  /// Encodes a single bit as [mark, space] timing pair
  List<int> _encodeBit(int bit) {
    return [_logicalZero, bit == 1 ? _logicalOne : _logicalZero];
  }
}
