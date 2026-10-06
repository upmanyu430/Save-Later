import os
import glob
import re

files = glob.glob('lib/ui/**/*.dart', recursive=True)
skip_files = ['neo_button.dart', 'bookmark_radial_menu.dart']

for file in files:
    if any(s in file for s in skip_files):
        continue
        
    with open(file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    modified = False
    new_lines = []
    
    for i, line in enumerate(lines):
        # Add import if needed later, check if we modify
        # 1. onTap: () => something,
        if re.search(r'(onTap|onPressed):\s*\(\)\s*=>', line):
            # Replace => expr, or => expr with { HapticFeedback.lightImpact(); expr; }
            # Note: expr might have a trailing comma.
            match = re.search(r'((?:onTap|onPressed):\s*\(\)\s*=>\s*)(.*)', line)
            if match:
                prefix = match.group(1)
                expr = match.group(2).strip()
                if expr.endswith(','):
                    expr = expr[:-1]
                new_line = line[:match.start()] + prefix.split('=>')[0] + '{ HapticFeedback.lightImpact(); ' + expr + '; },\n'
                new_lines.append(new_line)
                modified = True
                continue
                
        # 2. onTap: _someFunc,
        elif re.search(r'(onTap|onPressed):\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*,', line):
            match = re.search(r'((?:onTap|onPressed):)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*,', line)
            if match:
                prefix = match.group(1)
                func = match.group(2)
                new_line = line[:match.start()] + prefix + ' () { HapticFeedback.lightImpact(); ' + func + '(); },\n'
                new_lines.append(new_line)
                modified = True
                continue
                
        # 3. onTap: () {
        elif re.search(r'(onTap|onPressed):\s*\(\)\s*\{\s*$', line):
            new_lines.append(line)
            # Peek next line to see if it's already HapticFeedback
            if i + 1 < len(lines) and 'HapticFeedback' not in lines[i+1]:
                indent = line[:len(line) - len(line.lstrip())]
                new_lines.append(indent + '  HapticFeedback.lightImpact();\n')
                modified = True
            continue
            
        # 4. onTap: () async {
        elif re.search(r'(onTap|onPressed):\s*\(\)\s*async\s*\{\s*$', line):
            new_lines.append(line)
            if i + 1 < len(lines) and 'HapticFeedback' not in lines[i+1]:
                indent = line[:len(line) - len(line.lstrip())]
                new_lines.append(indent + '  HapticFeedback.lightImpact();\n')
                modified = True
            continue
            
        # 5. onTap: onTap,
        elif re.search(r'(onTap|onPressed):\s*(onTap|onPressed)\s*,', line):
            match = re.search(r'((?:onTap|onPressed):)\s*(onTap|onPressed)\s*,', line)
            if match:
                prefix = match.group(1)
                var = match.group(2)
                new_line = line[:match.start()] + prefix + ' () { HapticFeedback.lightImpact(); if (' + var + ' != null) ' + var + '(); },\n'
                new_lines.append(new_line)
                modified = True
                continue
                
        new_lines.append(line)
        
    if modified:
        content = "".join(new_lines)
        if 'HapticFeedback' in content and 'flutter/services.dart' not in content:
            content = "import 'package:flutter/services.dart';\n" + content
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Modified {file}")

