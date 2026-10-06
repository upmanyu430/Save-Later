with open('lib/ui/widgets/bookmark_radial_menu.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Change radii
content = content.replace('final double buttonRadius = 36.0;', 'final double buttonRadius = 34.0;')
content = content.replace('final double arcRadius = 85.0;', 'final double arcRadius = 65.0;')

# Add box shadow and adjust border
box_decoration = '''                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFD166) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 4),
                      ),'''

new_box_decoration = '''                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFD166) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),'''

content = content.replace(box_decoration, new_box_decoration)

# Add weight to icon if possible (using strokeWidth in Icon maybe? No, Icon doesn't have strokeWidth. We can just leave icon as is, the shadow is the main UI difference)
# Actually, the user image icons look like standard Material icons, but maybe they are a specific size. Let's keep size.
content = content.replace(
'''                      child: Icon(
                        action.icon, 
                        color: Colors.black, 
                        size: AppDimensions.iconSizeXl,
                      ),''',
'''                      child: Icon(
                        action.icon, 
                        color: Colors.black, 
                        size: 32.0,
                        weight: 700,
                      ),'''
)

with open('lib/ui/widgets/bookmark_radial_menu.dart', 'w', encoding='utf-8') as f:
    f.write(content)
