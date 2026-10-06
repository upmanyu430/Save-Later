import re
with open('lib/ui/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Wrap TextField in Center
content = content.replace(
'''                        child: TextField(
                          controller: _urlController,''',
'''                        child: Center(
                          child: TextField(
                            controller: _urlController,'''
)

# Need to close the Center widget properly
content = content.replace(
'''                          onSubmitted: (_) => _quickSave(),
                        ),
                      ),
                    ),
                  ),''',
'''                            onSubmitted: (_) => _quickSave(),
                          ),
                        ),
                      ),
                    ),
                  ),'''
)

with open('lib/ui/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
