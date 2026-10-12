import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../screens/icon_picker_screen.dart';
import 'neo_button.dart';
import 'package:save_later/config/app_constants.dart';


class CollectionEditorModal extends ConsumerStatefulWidget {
  final BookmarkCollection? existingCollection;
  final int? parentId;

  const CollectionEditorModal({super.key, this.existingCollection, this.parentId});

  @override
  ConsumerState<CollectionEditorModal> createState() => _CollectionEditorModalState();
}

class _CollectionEditorModalState extends ConsumerState<CollectionEditorModal> {
  late TextEditingController _nameController;
  late String _selectedColorHex;
  late int _selectedIconCode;

  final List<String> _colors = [
    'FFD166', 'FF9EAA', 'B19CD9', '4A90E2', '1ABC9C', '2ECC71', 'A2D149', 'F39C12',
    'F5DEB3', 'BDC3C7', '7F8C8D', '9B59B6', 'A0522D', '1C1C1C', 'E74C3C', '6A5ACD',
  ];

  final List<IconData> _quickIcons = [
    Icons.folder_outlined, Icons.star_outline, Icons.favorite_outline, Icons.menu_book, Icons.music_note_outlined, Icons.camera_alt_outlined, Icons.flag_outlined, Icons.nightlight_outlined,
    Icons.wb_sunny_outlined, Icons.cloud_outlined, Icons.location_on_outlined, Icons.calendar_today_outlined, Icons.public, Icons.card_giftcard, Icons.eco_outlined, Icons.work_outline,
    Icons.shopping_cart_outlined, Icons.flight_takeoff, Icons.directions_car_outlined, Icons.local_cafe_outlined, Icons.movie_outlined, Icons.headphones_outlined, Icons.palette_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingCollection?.name ?? '');
    _selectedColorHex = widget.existingCollection?.colorHex ?? _colors[0];
    _selectedIconCode = widget.existingCollection?.iconCodePoint ?? _quickIcons[0].codePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openFullIconPicker() async {
    HapticFeedback.lightImpact();
    final picked = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => IconPickerScreen(
          selectedColorHex: _selectedColorHex,
          currentIconCode: _selectedIconCode,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedIconCode = picked;
      });
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (widget.existingCollection == null) {
      ref.read(collectionNotifierProvider.notifier).addCollection(
            name,
            _selectedColorHex,
            _selectedIconCode,
            parentId: widget.parentId,
          );
    } else {
      ref.read(collectionNotifierProvider.notifier).updateCollection(
            widget.existingCollection!,
            name,
            _selectedColorHex,
            _selectedIconCode,
          );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCollection != null;
    
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 3),
          left: BorderSide(color: AppTheme.border, width: 3),
          right: BorderSide(color: AppTheme.border, width: 3),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXl),
                
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing
                          ? AppLocalizations.of(context)!.editCollection
                          : (widget.parentId != null
                              ? AppLocalizations.of(context)!.newSubCollection
                              : AppLocalizations.of(context)!.newCollection),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingSm),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border, width: 2),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: const Icon(Icons.close, size: AppDimensions.iconSizeMd),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingXxl),
                
                // Name Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.nameUpper, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('${_nameController.text.length}/40', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingSm),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppTheme.border, width: 2),
                  ),
                  child: TextField(
                    controller: _nameController,
                    maxLength: 40,
                    onChanged: (val) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Travel, Design Inspiration...',
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXl),
                
                // Color Picker
                Text(AppLocalizations.of(context)!.colorUpper, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final colorHex = _colors[index];
                    final color = Color(int.parse('0xFF$colorHex'));
                    final isSelected = _selectedColorHex == colorHex;
                    
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedColorHex = colorHex);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          border: Border.all(color: AppTheme.border, width: isSelected ? 3 : 2),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: color.computeLuminance() < 0.4 ? Colors.white : Colors.black,
                              )
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.paddingXl),
                
                // Icon Picker (3 rows of 8 = 24 items, with 24th item as 3-dots more button)
                Text(AppLocalizations.of(context)!.iconUpper, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 24,
                  itemBuilder: (context, index) {
                    final currentColor = Color(int.parse('0xFF$_selectedColorHex'));

                    // 24th item is the 3-dots / full page icon picker button
                    if (index == 23) {
                      final isQuickIconSelected = _quickIcons.any((icon) => icon.codePoint == _selectedIconCode);
                      final IconData displayIcon = isQuickIconSelected
                          ? Icons.more_horiz
                          : IconData(_selectedIconCode, fontFamily: 'MaterialIcons');
                      final isSelected = !isQuickIconSelected;

                      return GestureDetector(
                        onTap: () => _openFullIconPicker(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? currentColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            border: Border.all(color: AppTheme.border, width: isSelected ? 3 : 2),
                          ),
                          child: Icon(displayIcon, size: 20),
                        ),
                      );
                    }

                    final icon = _quickIcons[index];
                    final isSelected = _selectedIconCode == icon.codePoint;
                    
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedIconCode = icon.codePoint);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? currentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          border: Border.all(color: AppTheme.border, width: isSelected ? 3 : 2),
                        ),
                        child: Icon(icon, size: 20),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.paddingXxl),
                
                // Save Button
                Builder(
                  builder: (context) {
                    final isNameEmpty = _nameController.text.trim().isEmpty;
                    return NeoButton(
                      onPressed: !isNameEmpty
                          ? () {
                              HapticFeedback.lightImpact();
                              _save();
                            }
                          : () {},
                      color: !isNameEmpty ? const Color(0xFFFFD166) : AppTheme.cardColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          isEditing
                              ? AppLocalizations.of(context)!.updateCollection
                              : (widget.parentId != null
                                  ? AppLocalizations.of(context)!.createSubCollectionButton
                                  : AppLocalizations.of(context)!.createCollection),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: !isNameEmpty ? AppTheme.border : Colors.black38,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

