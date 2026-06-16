/// Abstract interface for IR blasting operations
/// Following Dependency Inversion Principle (D in SOLID)
abstract class IIrBlasterService {
  /// Transmits an IR signal with the given command byte
  ///
  /// [commandByte] - The 8-bit command code to transmit
  /// Throws [IrBlasterException] if transmission fails
  Future<void> transmitSignal(int commandByte);
}

/// Exception thrown when IR transmission fails
class IrBlasterException implements Exception {
  final String message;
  final dynamic originalError;

  IrBlasterException(this.message, [this.originalError]);

  @override
  String toString() =>
      'IrBlasterException: $message${originalError != null ? '\nCause: $originalError' : ''}';
}
