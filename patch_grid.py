import re

def patch_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add import if not exists
    if "'../widgets/bookmark_grid_item.dart'" not in content:
        content = content.replace("import '../widgets/neo_box.dart';", "import '../widgets/neo_box.dart';\nimport '../widgets/bookmark_grid_item.dart';")

    # Replace the itemBuilder block
    # We find itemBuilder: (context, index) { ... return GestureDetector( ... ); },
    # and replace it with:
    # itemBuilder: (context, index) {
    #   final b = bookmarks[index];
    #   return BookmarkGridItem(bookmark: b);
    # },
    
    # We'll use a regex that matches from itemBuilder: (context, index) { to }, where }, is before ),
    # Let's find itemBuilder: (context, index) {
    
    start_str = "itemBuilder: (context, index) {"
    if start_str not in content:
        return
        
    start_idx = content.find(start_str)
    
    # find the end of the itemBuilder function.
    # Because of nested brackets, we can count brackets.
    open_brackets = 0
    end_idx = -1
    in_builder = False
    
    for i in range(start_idx, len(content)):
        if content[i] == '{':
            open_brackets += 1
            in_builder = True
        elif content[i] == '}':
            open_brackets -= 1
            if in_builder and open_brackets == 0:
                end_idx = i + 1
                break
                
    if end_idx != -1:
        old_builder = content[start_idx:end_idx]
        new_builder = '''itemBuilder: (context, index) {
                              final b = bookmarks[index];
                              return BookmarkGridItem(bookmark: b);
                            }'''
        content = content.replace(old_builder, new_builder)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Patched {filepath}")
        
patch_file('lib/ui/screens/collection_detail_screen.dart')
patch_file('lib/ui/screens/search_screen.dart')
