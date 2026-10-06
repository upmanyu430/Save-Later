import re

def update_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Add forceBold to constructor if not present
    if 'final bool forceBold;' not in content:
        if 'class BookmarkGridItem' in content:
            content = content.replace(
                '  const BookmarkGridItem({\n    super.key,\n    required this.bookmark,\n  });',
                '  final bool forceBold;\n  const BookmarkGridItem({\n    super.key,\n    required this.bookmark,\n    this.forceBold = false,\n  });'
            )
        elif 'class FolderBox' in content:
            content = content.replace(
                '    this.icon = Icons.folder_outlined,\n  });',
                '    this.icon = Icons.folder_outlined,\n    this.forceBold = false,\n  });'
            )
            content = content.replace(
                '  final IconData icon;',
                '  final IconData icon;\n  final bool forceBold;'
            )

    # Make TextStyles dynamic
    content = content.replace('const TextStyle', 'TextStyle')
    
    # Replace fontWeight: FontWeight.XYZ with fontWeight: forceBold ? FontWeight.bold : FontWeight.XYZ
    content = re.sub(r'fontWeight:\s*(FontWeight\.\w+)', r'fontWeight: forceBold ? FontWeight.bold : \1', content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

update_file('lib/ui/widgets/bookmark_grid_item.dart')
update_file('lib/ui/widgets/folder_box.dart')

# Now update HomeScreen to pass forceBold: true
with open('lib/ui/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    home_content = f.read()

home_content = home_content.replace('BookmarkGridItem(', 'BookmarkGridItem(forceBold: true, ')
home_content = home_content.replace('FolderBox(', 'FolderBox(forceBold: true, ')

# Also make the TextField hint text bold
home_content = home_content.replace(
    'hintText: l10n.pasteLinkHint,',
    'hintText: l10n.pasteLinkHint,\n                          hintStyle: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),'
)

with open('lib/ui/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(home_content)

