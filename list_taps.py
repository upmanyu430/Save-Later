import os
import glob
import re

files = glob.glob('lib/ui/**/*.dart', recursive=True)
for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    matches = re.findall(r'onTap:\s*(.*?)[,\n]', content)
    if matches:
        print(f"File: {file} - onTap")
        
    matches2 = re.findall(r'onPressed:\s*(.*?)[,\n]', content)
    if matches2:
        print(f"File: {file} - onPressed")
