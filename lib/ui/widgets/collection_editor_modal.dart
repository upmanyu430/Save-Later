import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'app_modal_sheet.dart';
import 'neo_button.dart';
import 'stored_icon.dart';
import 'package:save_later/config/app_constants.dart';

class CollectionEditorModal extends ConsumerStatefulWidget {
  final BookmarkCollection? existingCollection;
  final int? parentId;

  /// Quick icons offered directly inside the editor (subset view). Public so
  /// [storedIcons] can materialize their code points at runtime while keeping
  /// the `Icons.*` references const (icon tree-shaking in release builds).
  static List<IconData> get quickIcons => _CollectionEditorModalState._allIcons;

  /// Calculates the exact height of CollectionEditorModal in its default collapsed state.
  static double getCollapsedModalHeight(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    // Outer padding: left 5.0, right 5.0 (total 10.0), capped at maxWidth 420
    final cardWidth = (screenWidth - 10.0) > 420.0 ? 420.0 : (screenWidth - 10.0);
    // Card border: 2.5 * 2 = 5.0. ScrollView horizontal padding: 18.0 * 2 = 36.0.
    final contentWidth = cardWidth - 41.0;

    // Grid item width for 8 columns with 7.0 spacing:
    final itemWidth = (contentWidth - (7 * 7.0)) / 8.0;

    // Color grid: 2 rows of items + 1 gap of 7.0
    final colorGridHeight = (2 * itemWidth) + 7.0;
    // Icon grid: 3 rows of items + 2 gaps of 7.0
    final iconGridHeight = (3 * itemWidth) + 14.0;

    // Fixed layout elements total: 310.33 dp (adjusted for 56.0 button height and modalActionButtonBottomPadding 31.5)
    const fixedContentHeight = 310.33;
    final baseHeight = fixedContentHeight + colorGridHeight + iconGridHeight;
    return baseHeight + bottomPadding;
  }

  const CollectionEditorModal(
      {super.key, this.existingCollection, this.parentId});

  @override
  ConsumerState<CollectionEditorModal> createState() =>
      _CollectionEditorModalState();
}

class _CollectionEditorModalState extends ConsumerState<CollectionEditorModal> {
  late final TextEditingController _nameController;
  late final ScrollController _scrollController;
  late final FocusNode _nameFocusNode;
  late final ValueNotifier<String> _selectedColorNotifier;
  late final ValueNotifier<int> _selectedIconNotifier;
  late final ValueNotifier<bool> _isExpandedNotifier;

  final List<String> _colors = [
    'FFD166',
    'FF9EAA',
    'B19CD9',
    '4A90E2',
    '1ABC9C',
    '2ECC71',
    'A2D149',
    'F39C12',
    'F5DEB3',
    'BDC3C7',
    '7F8C8D',
    '9B59B6',
    'A0522D',
    '1C1C1C',
    'E74C3C',
    '6A5ACD',
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

  List<IconData> _displayIconsFor(int selectedIconCode) {
    if (!_allIcons.any((icon) => icon.codePoint == selectedIconCode)) {
      return [
        ..._allIcons,
        storedIcon(selectedIconCode, kStoredIconFontFamily)
      ];
    }
    return _allIcons;
  }

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingCollection?.name ?? '');
    _scrollController = ScrollController();
    _nameFocusNode = FocusNode();
    final initialColorHex = widget.existingCollection?.colorHex ?? _colors[0];
    final initialIconCode =
        widget.existingCollection?.iconCodePoint ?? _allIcons[0].codePoint;
    _selectedColorNotifier = ValueNotifier<String>(initialColorHex);
    _selectedIconNotifier = ValueNotifier<int>(initialIconCode);

    final existingIconIndex =
        _allIcons.indexWhere((icon) => icon.codePoint == initialIconCode);
    final initiallyExpanded = existingIconIndex >= 23 ||
        (existingIconIndex == -1 && widget.existingCollection != null);
    _isExpandedNotifier = ValueNotifier<bool>(initiallyExpanded);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    _nameFocusNode.dispose();
    _selectedColorNotifier.dispose();
    _selectedIconNotifier.dispose();
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final selectedColorHex = _selectedColorNotifier.value;
    final selectedIconCode = _selectedIconNotifier.value;

    if (widget.existingCollection == null) {
      ref.read(collectionNotifierProvider.notifier).addCollection(
            name,
            selectedColorHex,
            selectedIconCode,
            parentId: widget.parentId,
          );
    } else {
      ref.read(collectionNotifierProvider.notifier).updateCollection(
            widget.existingCollection!,
            name,
            selectedColorHex,
            selectedIconCode,
          );
    }
    if (mounted) {
      dismissAppModalSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCollection != null;
    final l10n = AppLocalizations.of(context)!;
    final isHosted = isAppModalRouteHosted(context);
    final topClearance = resolveModalTopClearance(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxCardHeight = screenHeight - topClearance;

    final colors = context.appColors;
    final scrollContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isEditing
                    ? l10n.editCollection
                    : (widget.parentId != null
                        ? l10n.newSubCollection
                        : l10n.newCollection),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSm),
            SizedBox(
              width: AppDimensions.dialogHeaderButtonSize,
              height: AppDimensions.dialogHeaderButtonSize,
              child: NeoButton(
                onPressed: () => dismissAppModalSheet(context),
                padding: EdgeInsets.zero,
                color: colors.card,
                borderWidth: 2,
                borderRadius: AppDimensions.radiusSm,
                shadowOffset: 0,
                child: Icon(Icons.close, size: 18, color: colors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Name Field
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.nameUpper,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: colors.textPrimary)),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameController,
              builder: (context, value, _) {
                return Text(
                  '${value.text.length}/40',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 48.0,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: colors.border, width: 1.0),
            ),
            child: Center(
              child: RepaintBoundary(
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  maxLength: 40,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Travel, Design Inspiration...',
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Color Picker
        Text(l10n.colorUpper,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: colors.textPrimary)),
        const SizedBox(height: 5),
        RepaintBoundary(
          child: ValueListenableBuilder<String>(
            valueListenable: _selectedColorNotifier,
            builder: (context, selectedColorHex, _) {
              return GridView.builder(
                shrinkWrap: true,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                padding: EdgeInsets.zero,
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
                  final isSelected = selectedColorHex == colorHex;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _selectedColorNotifier.value = colorHex;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        border: Border.all(
                          color: colors.border,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colors.shadow,
                                  offset: const Offset(2, 2),
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
                                  : colors.onAccent,
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Icon Picker (3 rows collapsed with 3-dots at slot 24, or full 43 icons expanded)
        Text(l10n.iconUpper,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: colors.textPrimary)),
        const SizedBox(height: 5),
        RepaintBoundary(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _selectedColorNotifier,
                _selectedIconNotifier,
                _isExpandedNotifier,
              ]),
              builder: (context, _) {
                final selectedIconCode = _selectedIconNotifier.value;
                final isExpanded = _isExpandedNotifier.value;
                final icons = _displayIconsFor(selectedIconCode);
                final currentColor =
                    BookmarkCollection.parseColor(_selectedColorNotifier.value);
                final count = isExpanded ? icons.length : 24;

                return GridView.builder(
                  shrinkWrap: true,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  padding: EdgeInsets.zero,
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
                    if (!isExpanded && index == 23) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _isExpandedNotifier.value = true;
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                            border: Border.all(
                              color: colors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Icon(Icons.more_horiz,
                              size: 20, color: colors.textPrimary),
                        ),
                      );
                    }

                    final icon = icons[index];
                    final isSelected = selectedIconCode == icon.codePoint;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _selectedIconNotifier.value = icon.codePoint;
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? currentColor : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSm),
                          border: Border.all(
                            color: colors.border,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colors.shadow,
                                    offset: const Offset(2, 2),
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
                                  BookmarkCollection.isWhiteIconColor(
                                      currentColor)
                              ? Colors.white
                              : colors.textPrimary,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Save Button
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameController,
          builder: (context, value, _) {
            final isNameEmpty = value.text.trim().isEmpty;
            return SizedBox(
              height: AppDimensions.modalActionButtonHeight,
              width: double.infinity,
              child: NeoButton(
                onPressed: !isNameEmpty ? _save : () {},
                color: !isNameEmpty
                    ? const Color(0xFFFFD166)
                    : colors.card,
                shadowColor: colors.shadow,
                padding: EdgeInsets.zero,
                borderRadius: AppDimensions.radiusMd,
                shadowOffset: 2.0,
                child: Center(
                  child: Text(
                    isEditing
                        ? l10n.updateCollection
                        : (widget.parentId != null
                            ? l10n.createSubCollectionButton
                            : l10n.createCollection),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: !isNameEmpty ? colors.onAccent : colors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );

    final cachedScrollContent = RepaintBoundary(child: scrollContent);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => dismissAppModalSheet(context),
      child: Padding(
        padding: EdgeInsets.only(
          left: 5.0,
          right: 5.0,
          top: isHosted ? 0.0 : topClearance,
          bottom: 0,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: isHosted ? 1.0 : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: maxCardHeight,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(55),
                    border: Border.all(color: colors.border, width: 2.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pinned Drag Handle ONLY
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        child: RepaintBoundary(
                          child: AppModalImeBuilder(
                            child: cachedScrollContent,
                            builder: (
                              scrollContext,
                              bottomInset,
                              safeBottom,
                              child,
                            ) {
                              final closedBottomPadding =
                                  AppDimensions.modalActionButtonBottomPadding +
                                      safeBottom;
                              final bottomPadding = math.max(
                                closedBottomPadding,
                                14.0 + bottomInset,
                              );

                              return SingleChildScrollView(
                                controller: _scrollController,
                                padding: EdgeInsets.fromLTRB(
                                  18.0,
                                  8.0,
                                  18.0,
                                  bottomPadding,
                                ),
                                child: child,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
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
