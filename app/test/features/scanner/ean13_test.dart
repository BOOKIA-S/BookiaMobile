import 'package:bookia_mobile/features/scanner/domain/entities/ean13.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts ISBN-13 codes with the right check digit', () {
    expect(Ean13.isIsbn('9780306406157'), isTrue);
    expect(Ean13.isIsbn('9786071612342'), isTrue);
    expect(Ean13.isIsbn('9791000000008'), isTrue);
  });

  test('rejects a wrong check digit', () {
    expect(Ean13.isValid('9780306406158'), isFalse);
    expect(Ean13.isIsbn('9780306406158'), isFalse);
  });

  test('a valid product EAN that is not from 978/979 is not an ISBN', () {
    expect(Ean13.isValid('4006381333931'), isTrue);
    expect(Ean13.isIsbn('4006381333931'), isFalse);
  });

  test('rejects anything that is not 13 digits', () {
    for (final code in ['', '978030640615', '97803064061577', '978-0306406']) {
      expect(Ean13.isValid(code), isFalse, reason: code);
    }
  });
}
