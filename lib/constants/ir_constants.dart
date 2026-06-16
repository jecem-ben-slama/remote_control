/// Constants for IR protocol configuration
/// NEC standard protocol settings for 38kHz carrier frequency
abstract class IRConstants {
  // NEC Protocol Configuration
  static const int carrierFrequencyHz = 38000;

  // Timing Durations (microseconds)
  static const int headerMarkUs = 9000;
  static const int headerSpaceUs = 4500;
  static const int logicalOneSpaceUs = 1690;
  static const int logicalZeroSpaceUs = 560;
  static const int logicalMarkUs = 560;
  static const int burstStopLineUs = 40000;

  // Protocol Frame Structure
  static const int addressBits = 8;
  static const int commandBits = 8;
  static const int totalBitsPerFrame =
      addressBits * 2 +
      commandBits * 2; // address + inverted + command + inverted

  // Fixed Address (NEC device address 0x01)
  static const int deviceAddress = 0x01;

  // Command Range
  static const int minCommandCode = 0x00;
  static const int maxCommandCode = 0xFF;
  static const int totalCommands = 256;
}
