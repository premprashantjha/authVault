/// PIN validation utilities for security
class PinValidator {
  /// Minimum PIN length
  static const int minLength = 6;

  /// Validate PIN strength
  /// Returns null if valid, error message if invalid
  static String? validatePin(String pin) {
    if (pin.isEmpty) {
      return 'PIN cannot be empty';
    }

    if (pin.length < minLength) {
      return 'PIN must be at least $minLength digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      return 'PIN must contain only numbers';
    }

    if (_isSequentialPin(pin)) {
      return 'PIN cannot be sequential (e.g., 123456)';
    }

    if (_isRepeatedPin(pin)) {
      return 'PIN cannot have all same digits';
    }

    if (_isCommonPin(pin)) {
      return 'This PIN is too common. Please choose a different one';
    }

    return null; // Valid PIN
  }

  /// Check if PIN is valid (returns bool)
  static bool isValidPin(String pin) {
    return validatePin(pin) == null;
  }

  /// Check for sequential numbers
  static bool _isSequentialPin(String pin) {
    // Check ascending sequences
    final ascending = [
      '012345', '123456', '234567', '345678', '456789',
      '0123456', '1234567', '2345678', '3456789',
      '01234567', '12345678', '23456789'
    ];

    // Check descending sequences
    final descending = [
      '543210', '654321', '765432', '876543', '987654',
      '6543210', '7654321', '8765432', '9876543',
      '76543210', '87654321', '98765432'
    ];

    final allSequential = [...ascending, ...descending];

    for (final seq in allSequential) {
      if (pin.contains(seq)) {
        return true;
      }
    }

    return false;
  }

  /// Check for repeated digits
  static bool _isRepeatedPin(String pin) {
    // Check if all digits are the same
    if (RegExp(r'^(.)\1+$').hasMatch(pin)) {
      return true;
    }

    // Check for patterns like 112233 or 121212
    if (pin.length >= 6) {
      // Check AA pattern (111111, 000000, etc.)
      if (RegExp(r'^(\d)\1{5,}$').hasMatch(pin)) {
        return true;
      }

      // Check AABB pattern (112233, 445566, etc.)
      if (RegExp(r'^(\d)\1(\d)\2(\d)\3$').hasMatch(pin)) {
        return true;
      }

      // Check ABAB pattern (121212, 343434, etc.)
      if (RegExp(r'^(\d{2})\1{2,}$').hasMatch(pin)) {
        return true;
      }

      // Check ABCABC pattern (123123, 456456, etc.)
      if (pin.length >= 6) {
        final half = pin.length ~/ 2;
        final firstHalf = pin.substring(0, half);
        final secondHalf = pin.substring(half);
        if (firstHalf == secondHalf) {
          return true;
        }
      }
    }

    return false;
  }

  /// Check against list of most common PINs
  static bool _isCommonPin(String pin) {
    // Top 50 most common PINs from data breaches
    const commonPins = [
      '123456', '654321', '111111', '000000', '123123',
      '666666', '121212', '112233', '789456', '159753',
      '131313', '123321', '777777', '123654', '456123',
      '888888', '555555', '252525', '212121', '101010',
      '222222', '333333', '444444', '999999', '147258',
      '963852', '741852', '852963', '098765', '876543',
      '123789', '321654', '456789', '147852', '258963',
      '369258', '753951', '159357', '147963', '951753',
      '010203', '102030', '111213', '141516', '161718',
      '192021', '202122', '232425', '262728', '293031',
    ];

    return commonPins.contains(pin);
  }

  /// Get PIN strength indicator (1-5)
  static int getPinStrength(String pin) {
    if (pin.length < minLength) return 0;
    if (validatePin(pin) != null) return 1;

    int strength = 2; // Base strength for valid PIN

    // Add points for length
    if (pin.length >= 8) strength++;
    if (pin.length >= 10) strength++;

    // Check for digit variety
    final uniqueDigits = pin.split('').toSet().length;
    if (uniqueDigits >= 5) strength++;

    return strength > 5 ? 5 : strength;
  }

  /// Get strength description
  static String getStrengthDescription(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }
}
