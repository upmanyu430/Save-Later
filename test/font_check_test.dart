import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Gabarito is available in google_fonts', () {
    final style = GoogleFonts.gabarito();
    expect(style.fontFamily, contains('Gabarito'));
    final textTheme = GoogleFonts.gabaritoTextTheme();
    expect(textTheme.bodyMedium?.fontFamily, contains('Gabarito'));
  });
}
