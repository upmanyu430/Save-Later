import re

with open('lib/ui/widgets/bookmark_grid_item.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add forceBold to constructor
content = content.replace(
    '''  const BookmarkGridItem({
    super.key,
    required this.bookmark,
  });''',
    '''  final bool forceBold;
  const BookmarkGridItem({
    super.key,
    required this.bookmark,
    this.forceBold = false,
  });'''
)

# Replace TextStyles to respect forceBold
content = re.sub(
    r'style: const TextStyle\((.*?fontWeight:\s*)(.*?)(,.*?)\)',
    r'style: TextStyle(\1forceBold ? FontWeight.bold : \2\3)',
    content
)
# Since the regex above handles single line, some might be multi-line. Let's just do a simpler replace.
