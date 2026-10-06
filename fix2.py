with open('lib/ui/widgets/bookmark_grid_item.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    '  final VoidCallback? onSelectTapped;',
    '  final VoidCallback? onSelectTapped;\n  final bool forceBold;'
)

content = content.replace(
    '    this.onSelectTapped,\n  });',
    '    this.onSelectTapped,\n    this.forceBold = false,\n  });'
)

# And because BookmarkGridItem is a StatefulWidget, I need to use widget.forceBold instead of orceBold in the state!
content = content.replace('forceBold ?', 'widget.forceBold ?')

with open('lib/ui/widgets/bookmark_grid_item.dart', 'w', encoding='utf-8') as f:
    f.write(content)
