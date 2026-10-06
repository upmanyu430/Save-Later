import re

with open('lib/ui/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add google_fonts import if missing
if 'google_fonts.dart' not in content:
    content = content.replace(
        "import 'package:flutter_riverpod/flutter_riverpod.dart';",
        "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:google_fonts/google_fonts.dart';"
    )

content = content.replace(
    '''style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1,
                ),''',
    '''style: GoogleFonts.spaceMono(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  letterSpacing: -1,
                ),'''
)

content = content.replace(
    '''style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),''',
    '''style: GoogleFonts.spaceMono(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),'''
)

with open('lib/ui/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
