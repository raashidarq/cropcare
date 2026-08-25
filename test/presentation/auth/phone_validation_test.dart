import 'package:flutter_test/flutter_test.dart';

bool isValidPhoneNumber(String phone) {
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone.trim());
}

void main() {
  group('Phone Number Validation (E.164)', () {
    test('accepts valid international phone numbers', () {
      expect(isValidPhoneNumber('+94771234567'), isTrue);
      expect(isValidPhoneNumber('+447700900999'), isTrue);
      expect(isValidPhoneNumber('+12025551234'), isTrue);
      expect(isValidPhoneNumber('+94112345678'), isTrue);
    });

    test('rejects invalid phone numbers', () {
      expect(isValidPhoneNumber('0771234567'), isFalse, reason: 'Missing leading +');
      expect(isValidPhoneNumber('abc'), isFalse, reason: 'Alphabetic string');
      expect(isValidPhoneNumber('+'), isFalse, reason: 'Only plus sign');
      expect(isValidPhoneNumber('+1234'), isFalse, reason: 'Too short (< 7 digits)');
      expect(isValidPhoneNumber('+0123456789'), isFalse, reason: 'Country code cannot start with 0');
      expect(isValidPhoneNumber(''), isFalse, reason: 'Empty string');
    });
  });
}
