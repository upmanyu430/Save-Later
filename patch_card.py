import re

with open('lib/ui/screens/collection_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_card = r'child: NeoBox\(\s*padding: const EdgeInsets\.all\(0\),\s*borderRadius: 12,\s*child: Column\([\s\S]*?Expanded\(\s*flex: 4,[\s\S]*?child: Padding\([\s\S]*?padding: const EdgeInsets\.all\(12\.0\),[\s\S]*?child: Column\([\s\S]*?crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[[\s\S]*?Text\([\s\S]*?b\.title \?\? b\.url,[\s\S]*?style: const TextStyle\(fontSize: 14, fontWeight: FontWeight\.bold, height: 1\.2\),[\s\S]*?maxLines: 2,[\s\S]*?overflow: TextOverflow\.ellipsis,[\s\S]*?\),[\s\S]*?const Spacer\(\),[\s\S]*?Row\([\s\S]*?children: \[[\s\S]*?const Icon\(Icons\.public, size: 14, color: Colors\.grey\),[\s\S]*?const SizedBox\(width: 4\),[\s\S]*?Expanded\([\s\S]*?child: Text\([\s\S]*?b\.sourceDomain \?\? \'Unknown\',[\s\S]*?style: const TextStyle\(fontSize: 12, color: Colors\.grey, fontWeight: FontWeight\.w600\),[\s\S]*?maxLines: 1,[\s\S]*?overflow: TextOverflow\.ellipsis,[\s\S]*?\),[\s\S]*?\),[\s\S]*?\],[\s\S]*?\)[\s\S]*?\],[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),[\s\S]*?\],[\s\S]*?\),[\s\S]*?\)'

new_card = '''child: NeoBox(
                                  padding: const EdgeInsets.all(0),
                                  borderRadius: 12,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            border: Border(bottom: BorderSide(color: AppTheme.border, width: 2.5)),
                                            color: Color(0xFFF0F0F0),
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(9.5)),
                                          ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(9.5)),
                                                child: b.imageUrl != null
                                                    ? Image.network(b.imageUrl!.startsWith('//') ? 'https:' + b.imageUrl! : b.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey))
                                                    : Center(
                                                        child: Text(
                                                          b.title != null && b.title!.isNotEmpty ? b.title![0].toUpperCase() : '?',
                                                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.border),
                                                        ),
                                                      ),
                                              ),
                                              if (!b.isRead)
                                                Positioned(
                                                  top: 6,
                                                  left: 6,
                                                  child: Transform.rotate(
                                                    angle: -0.1,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFFD166),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: AppTheme.border, width: 1.5),
                                                      ),
                                                      child: const Text(
                                                        'NEW',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w900,
                                                          color: AppTheme.border,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                b.title ?? b.url,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const Spacer(),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 16,
                                                    height: 16,
                                                    decoration: const BoxDecoration(
                                                      color: AppTheme.border,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        b.sourceDomain != null && b.sourceDomain!.isNotEmpty ? b.sourceDomain![0].toUpperCase() : '?',
                                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      b.sourceDomain ?? 'Unknown',
                                                      style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )'''

# Just to be safe, I will find exactly where the grid view item builder is and replace it.
content_re = re.sub(old_card, new_card, content)

if content == content_re:
    print("Regex failed to match!")
else:
    with open('lib/ui/screens/collection_detail_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content_re)
    print("Replaced successfully!")
