import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Bricolage Grotesque is available in google_fonts', () {
    final style = GoogleFonts.bricolageGrotesque();
    expect(style.fontFamily, contains('BricolageGrotesque'));
    final textTheme = GoogleFonts.bricolageGrotesqueTextTheme();
    expect(textTheme.bodyMedium?.fontFamily, contains('BricolageGrotesque'));
  });
}
