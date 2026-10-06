with open('lib/ui/widgets/bookmark_grid_item.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if 'final bool forceBold;' not in content:
    content = content.replace(
        '  const BookmarkGridItem({\n    super.key,\n    required this.bookmark,\n  });',
        '  final bool forceBold;\n  const BookmarkGridItem({\n    super.key,\n    required this.bookmark,\n    this.forceBold = false,\n  });'
    )
    with open('lib/ui/widgets/bookmark_grid_item.dart', 'w', encoding='utf-8') as f:
        f.write(content)
