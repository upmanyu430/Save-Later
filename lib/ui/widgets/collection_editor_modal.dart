import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
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
  bool _isExpanded = false;

  final List<String> _colors = [
    'FFD166', 'FF9EAA', 'B19CD9', '4A90E2', '1ABC9C', '2ECC71', 'A2D149', 'F39C12',
    'F5DEB3', 'BDC3C7', '7F8C8D', '9B59B6', 'A0522D', '1C1C1C', 'E74C3C', '6A5ACD',
  ];

  static final List<IconData> _allIcons = [
    // Row 1
    Icons.folder_outlined,
    Icons.star_outline,
    Icons.favorite_outline,
    Icons.menu_book,
    Icons.music_note_outlined,
    Icons.camera_alt_outlined,
    Icons.flag_outlined,
    Icons.nightlight_outlined,
    // Row 2
    Icons.wb_sunny_outlined,
    Icons.cloud_outlined,
    Icons.location_on_outlined,
    Icons.calendar_today_outlined,
    Icons.public,
    Icons.card_giftcard,
    Icons.eco_outlined,
    Icons.work_outline,
    // Row 3
    Icons.shopping_cart_outlined,
    Icons.flight_takeoff,
    Icons.directions_car_outlined,
    Icons.local_cafe_outlined,
    Icons.movie_outlined,
    Icons.headphones_outlined,
    Icons.palette_outlined,
    Icons.sports_esports_outlined,
    // Row 4
    Icons.fitness_center,
    Icons.attach_money,
    Icons.phone_outlined,
    Icons.desktop_windows_outlined,
    Icons.access_time,
    Icons.lightbulb_outline,
    Icons.school_outlined,
    Icons.shield_outlined,
    // Row 5
    Icons.restaurant_outlined,
    Icons.tv,
    Icons.notifications_none,
    Icons.vpn_key_outlined,
    Icons.inventory_2_outlined,
    Icons.layers_outlined,
    Icons.code,
    Icons.bolt,
    // Row 6
    Icons.bookmark_border,
    Icons.local_offer_outlined,
    Icons.home_outlined,
  ];

  List<IconData> get _displayIcons {
    if (!_allIcons.any((icon) => icon.codePoint == _selectedIconCode)) {
      return [..._allIcons, IconData(_selectedIconCode, fontFamily: 'MaterialIcons')];
    }
    return _allIcons;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingCollection?.name ?? '');
    _selectedColorHex = widget.existingCollection?.colorHex ?? _colors[0];
    _selectedIconCode = widget.existingCollection?.iconCodePoint ?? _allIcons[0].codePoint;

    final existingIconIndex = _allIcons.indexWhere((icon) => icon.codePoint == _selectedIconCode);
    if (existingIconIndex >= 23 || (existingIconIndex == -1 && widget.existingCollection != null)) {
      _isExpanded = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCollection != null;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final view = View.of(context);
    final windowPadding = MediaQueryData.fromView(view).padding;
    final statusBarHeight = windowPadding.top > 0
        ? windowPadding.top
        : MediaQuery.paddingOf(context).top;
    final topClearance = statusBarHeight + 16.0;
    final bottomInset = viewInsets.bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxCardHeight = screenHeight - bottomInset - topClearance;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: EdgeInsets.only(
          left: 5.0,
          right: 5.0,
          top: topClearance,
          bottom: bottomInset,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: maxCardHeight,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(55),
                  border: Border.all(color: AppTheme.border, width: 2.5),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18.0,
                    12.0,
                    18.0,
                    bottomInset > 0 ? 14.0 : (14.0 + MediaQuery.paddingOf(context).bottom),
                  ),
                    child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isEditing
                              ? AppLocalizations.of(context)!.editCollection
                              : (widget.parentId != null
                                  ? AppLocalizations.of(context)!.newSubCollection
                                  : AppLocalizations.of(context)!.newCollection),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingSm),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: NeoButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          padding: EdgeInsets.zero,
                          color: Colors.white,
                          borderWidth: 2,
                          borderRadius: AppDimensions.radiusSm,
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Name Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.nameUpper, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('${_nameController.text.length}/40', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 48.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(color: AppTheme.border, width: 1.0),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _nameController,
                          maxLength: 40,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (val) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Travel, Design Inspiration...',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 15),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            border: InputBorder.none,
                            isDense: true,
                            counterText: '',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Color Picker
                  Text(AppLocalizations.of(context)!.colorUpper, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 5),
                  GridView.builder(
                    shrinkWrap: true,
                    clipBehavior: Clip.none,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      crossAxisSpacing: 7,
                      mainAxisSpacing: 7,
                    ),
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      final colorHex = _colors[index];
                      final color = BookmarkCollection.parseColor(colorHex);
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
                            border: Border.all(
                              color: AppTheme.border,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? const [
                                    BoxShadow(
                                      color: AppTheme.border,
                                      offset: Offset(2, 2),
                                      blurRadius: 0,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: BookmarkCollection.isWhiteIconColor(color)
                                      ? Colors.white
                                      : Colors.black,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  
                  // Icon Picker (3 rows collapsed with 3-dots at slot 24, or full 43 icons expanded)
                  Text(AppLocalizations.of(context)!.iconUpper, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 5),
                  Builder(
                    builder: (context) {
                      final icons = _displayIcons;
                      final currentColor = BookmarkCollection.parseColor(_selectedColorHex);
                      final count = _isExpanded ? icons.length : 24;

                      return GridView.builder(
                        shrinkWrap: true,
                        clipBehavior: Clip.none,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          crossAxisSpacing: 7,
                          mainAxisSpacing: 7,
                        ),
                        itemCount: count,
                        itemBuilder: (context, index) {
                          // In collapsed state, slot 24 (index 23) is the 3-dots expand button
                          if (!_isExpanded && index == 23) {
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _isExpanded = true);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                                  border: Border.all(
                                    color: AppTheme.border,
                                    width: 1.0,
                                  ),
                                ),
                                child: const Icon(Icons.more_horiz, size: 20),
                              ),
                            );
                          }

                          final icon = icons[index];
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
                                border: Border.all(
                                  color: AppTheme.border,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? const [
                                        BoxShadow(
                                          color: AppTheme.border,
                                          offset: Offset(2, 2),
                                          blurRadius: 0,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                icon,
                                size: 20,
                                color: isSelected &&
                                        BookmarkCollection.isWhiteIconColor(currentColor)
                                    ? Colors.white
                                    : AppTheme.border,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                
                // Save Button
                Builder(
                  builder: (context) {
                    final isNameEmpty = _nameController.text.trim().isEmpty;
                    return SizedBox(
                      height: 48.0,
                      width: double.infinity,
                      child: NeoButton(
                        onPressed: !isNameEmpty ? _save : () {},
                        color: !isNameEmpty ? const Color(0xFFFFD166) : AppTheme.cardColor,
                        padding: EdgeInsets.zero,
                        borderWidth: 1.0,
                        borderRadius: AppDimensions.radiusMd,
                        child: Center(
                          child: Text(
                            isEditing
                                ? AppLocalizations.of(context)!.updateCollection
                                : (widget.parentId != null
                                    ? AppLocalizations.of(context)!.createSubCollectionButton
                                    : AppLocalizations.of(context)!.createCollection),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: !isNameEmpty ? AppTheme.border : Colors.black38,
                            ),
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
    ),
  ),
),
),
),
);
  }
}

