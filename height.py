with open('lib/ui/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# I want to wrap the Row's children in SizedBox(height: 56.0).
# Let's replace the NeoBox( and NeoButton(
content = content.replace(
'''                  Expanded(
                    child: NeoBox(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg, vertical: 4.0),
                      borderRadius: AppDimensions.radiusMd,''',
'''                  Expanded(
                    child: SizedBox(
                      height: 56.0,
                      child: NeoBox(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg, vertical: 0.0),
                        borderRadius: AppDimensions.radiusMd,'''
)

content = content.replace(
'''                  NeoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                    borderRadius: AppDimensions.radiusMd,''',
'''                  SizedBox(
                    height: 56.0,
                    width: 56.0,
                    child: NeoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: AppDimensions.radiusMd,'''
)

with open('lib/ui/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
