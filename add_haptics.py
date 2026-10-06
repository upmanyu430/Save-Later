import os
import glob
import re

files = glob.glob('lib/ui/**/*.dart', recursive=True)

# We will skip neo_button.dart since it already handles its own tap events with haptics
skip_files = ['lib/ui/widgets/neo_button.dart', 'lib/ui\\\\widgets\\\\neo_button.dart']

for file in files:
    if any(file.endswith(s) for s in ['neo_button.dart']):
        continue
        
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
        
    original = content
    
    # Replace onTap: () => expr, with onTap: () { HapticFeedback.lightImpact(); expr; },
    # We use a robust regex that matches until the next comma or closing parenthesis.
    
    # 1. onTap: () => ...
    content = re.sub(r'(onTap|onPressed):\s*\(\)\s*=>\s*(.*?)([,)])',
                     r'\1: () { HapticFeedback.lightImpact(); \2; }\3', content)
                     
    # 2. onTap: someFunc,
    # (where someFunc is not starting with () or {)
    content = re.sub(r'(onTap|onPressed):\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*([,)])',
                     r'\1: () { HapticFeedback.lightImpact(); \2(); }\3', content)
                     
    # 3. onTap: () {
    # Only replace if HapticFeedback is not the immediately following line
    content = re.sub(r'(onTap|onPressed):\s*\(\)\s*\{\s*(?!HapticFeedback)',
                     r'\1: () {\n                                HapticFeedback.lightImpact();\n                                ', content)
                     
    # 4. onTap: () async {
    content = re.sub(r'(onTap|onPressed):\s*\(\)\s*async\s*\{\s*(?!HapticFeedback)',
                     r'\1: () async {\n                                HapticFeedback.lightImpact();\n                                ', content)

    # 5. onTap: onTap, (in widgets where it's passed as a variable)
    # Wait, the rule #2 would replace onTap: onTap, with onTap: () { HapticFeedback.lightImpact(); onTap(); },
    # Let's see if that's safe. If onTap is nullable, it will crash.
    # We should fix nullable ones manually if they break. Let's do a quick fix for onTap() if it might be nullable:
    content = re.sub(r'HapticFeedback\.lightImpact\(\);\s*onTap\(\);',
                     r'HapticFeedback.lightImpact(); if (onTap != null) onTap();', content)
                     
    # Add import if we used HapticFeedback
    if 'HapticFeedback' in content and 'flutter/services.dart' not in content:
        content = "import 'package:flutter/services.dart';\n" + content
        
    if content != original:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Modified {file}")

