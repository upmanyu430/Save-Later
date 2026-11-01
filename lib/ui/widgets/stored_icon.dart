import 'package:flutter/material.dart';
import '../../models/collection.dart';
import '../screens/icon_picker_screen.dart';
import 'collection_editor_modal.dart';

/// Lookup table of every icon the app can store, keyed by code point.
///
/// Every entry is a *const* `Icons.*` reference kept alive by the icon picker
/// and the collection editor, so Flutter's icon tree-shaker preserves these
/// glyphs in the compiled MaterialIcons font. This lets us materialize
/// persisted `iconCodePoint` values at runtime without breaking
/// `flutter build apk --release` ("Avoid non-constant invocations of IconData").
final Map<int, IconData> storedIcons = {
  for (final item in IconPickerScreen.offeredIcons) item.icon.codePoint: item.icon,
  for (final icon in CollectionEditorModal.quickIcons) icon.codePoint: icon,
};

/// Materializes a stored icon. Card/folder widgets must use this instead of
/// constructing `IconData(codePoint, ...)` directly (which is not const and
/// breaks icon tree-shaking in release builds).
///
/// Falls back to the standard folder icon when the stored code point is not
/// offered by the picker (e.g. legacy data or an unknown font family).
IconData storedIcon(
  int codePoint,
  String fontFamily, {
  IconData fallback = Icons.folder_outlined,
}) {
  if (fontFamily != kStoredIconFontFamily) return fallback;
  return storedIcons[codePoint] ?? fallback;
}
