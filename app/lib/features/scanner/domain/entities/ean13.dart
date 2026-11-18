/// Rules of the EAN-13 barcode printed on a book's back cover.
abstract final class Ean13 {
  static final _digits = RegExp(r'^\d{13}$');

  /// 13 digits whose last one is the right check digit.
  static bool isValid(String code) {
    if (!_digits.hasMatch(code)) return false;
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(code[i]) * (i.isEven ? 1 : 3);
    }
    return (10 - sum % 10) % 10 == int.parse(code[12]);
  }

  /// A valid EAN-13 from "Bookland" (978 or 979), so it is an ISBN-13.
  static bool isIsbn(String code) =>
      isValid(code) && (code.startsWith('978') || code.startsWith('979'));
}
