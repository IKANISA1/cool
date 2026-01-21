/// Input validators for form fields
class Validators {
  Validators._();

  /// Regular expression for phone number validation (Sub-Saharan Africa)
  ///
  /// Supports:
  /// - Rwanda: +250xxxxxxxxx
  /// - Kenya: +254xxxxxxxxx
  /// - Uganda: +256xxxxxxxxx
  /// - Tanzania: +255xxxxxxxxx
  /// - Nigeria: +234xxxxxxxxxx
  /// - South Africa: +27xxxxxxxxx
  static final RegExp _phoneRegExp = RegExp(
    r'^\+?(250|254|256|255|234|27|257|243)\d{8,10}$',
  );

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    
    if (!_phoneRegExp.hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate OTP code (6 digits)
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Verification code is required';
    }

    if (value.length != 6) {
      return 'Code must be 6 digits';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Code must contain only numbers';
    }

    return null;
  }

  /// Validate name (min 2 chars, max 100)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Name must be less than 100 characters';
    }

    return null;
  }

  /// Validate vehicle plate number
  static String? validatePlateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Plate number is required';
    }

    if (value.length < 3 || value.length > 20) {
      return 'Please enter a valid plate number';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters';
    }

    return null;
  }

  /// Validate number range
  static String? validateNumberRange(
    int? value,
    int min,
    int max, [
    String? fieldName,
  ]) {
    if (value == null) {
      return '${fieldName ?? 'Value'} is required';
    }

    if (value < min || value > max) {
      return '${fieldName ?? 'Value'} must be between $min and $max';
    }

    return null;
  }
}
