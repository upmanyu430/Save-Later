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

  const CollectionEditorModal({super.key, this.existingCollection});

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

  final List<IconData> _icons = [
    Icons.folder_outlined, Icons.star_outline, Icons.favorite_outline, Icons.menu_book, Icons.music_note_outlined, Icons.camera_alt_outlined, Icons.flag_outlined, Icons.nightlight_outlined,
    Icons.wb_sunny_outlined, Icons.cloud_outlined, Icons.location_on_outlined, Icons.calendar_today_outlined, Icons.public, Icons.card_giftcard, Icons.eco_outlined, Icons.work_outline,
    Icons.shopping_cart_outlined, Icons.flight_takeoff, Icons.directions_car_outlined, Icons.local_cafe_outlined, Icons.movie_outlined, Icons.headphones_outlined, Icons.palette_outlined, Icons.sports_esports_outlined,
    Icons.fitness_center, Icons.attach_money, Icons.phone_outlined, Icons.desktop_windows_outlined, Icons.access_time, Icons.lightbulb_outline, Icons.school_outlined, Icons.shield_outlined,
    Icons.restaurant_outlined, Icons.tv, Icons.notifications_none, Icons.vpn_key_outlined, Icons.inventory_2_outlined, Icons.layers_outlined, Icons.code, Icons.bolt,
    Icons.bookmark_border, Icons.local_offer_outlined, Icons.home_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingCollection?.name ?? '');
    _selectedColorHex = widget.existingCollection?.colorHex ?? _colors[0];
    _selectedIconCode = widget.existingCollection?.iconCodePoint ?? _icons[0].codePoint;
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
      ref.read(collectionNotifierProvider.notifier).addCollection(name, _selectedColorHex, _selectedIconCode);
    } else {
      ref.read(collectionNotifierProvider.notifier).updateCollection(widget.existingCollection!, name, _selectedColorHex, _selectedIconCode);
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
        border: Border(top: BorderSide(color: AppTheme.border, width: 3)),
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
                          : AppLocalizations.of(context)!.newCollection,
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
                      onTap: () => setState(() => _selectedColorHex = colorHex),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                          border: Border.all(color: AppTheme.border, width: isSelected ? 3 : 2),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 16) : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.paddingXl),
                
                // Icon Picker
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
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final icon = _icons[index];
                    final isSelected = _selectedIconCode == icon.codePoint;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconCode = icon.codePoint),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD166) : Colors.transparent,
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
                NeoButton(
                  onPressed: _nameController.text.isNotEmpty ? _save : () {},
                  color: const Color(0xFFFFD166),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      isEditing
                          ? AppLocalizations.of(context)!.updateCollection
                          : AppLocalizations.of(context)!.createCollection,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

