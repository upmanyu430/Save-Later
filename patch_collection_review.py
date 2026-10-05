import re

with open('lib/ui/screens/collection_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('onTap: () => _showAddLinkModal(context, ref),', 'onTap: () => context.push(\'/review\', extra: widget.collection),')
content = content.replace('child: const Icon(Icons.add_link, size: 28),', 'child: const Icon(Icons.style, size: 28),')

with open('lib/ui/screens/collection_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
