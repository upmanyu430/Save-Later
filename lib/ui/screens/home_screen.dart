import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();

  void _quickSave() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      // Basic validation
      if (!url.startsWith('http')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid URL starting with http/https')),
        );
        return;
      }
      ref.read(bookmarkNotifierProvider.notifier).quickSave(url);
      _urlController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _showAddCollectionModal() {
    // A simplified modal for adding collections
    String name = '';
    String colorHex = 'FF9EAA'; // Default Primary
    int iconCode = Icons.folder.codePoint;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: NeoBox(
            borderRadius: 32,
            padding: const EdgeInsets.all(24),
            color: AppTheme.background,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'New Collection',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Collection Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 24),
                NeoButton(
                  onPressed: () {
                    if (name.isNotEmpty) {
                      ref.read(collectionNotifierProvider.notifier).addCollection(name, colorHex, iconCode);
                      Navigator.pop(context);
                    }
                  },
                  child: const Center(
                    child: Text(
                      'Create Collection',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final isSaving = ref.watch(bookmarkNotifierProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Save now.\nFind anytime.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.style, size: 32), // Review mode icon
                        onPressed: () => context.push('/review'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings, size: 32),
                        onPressed: () {}, // TODO: Settings
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),

              // Quick Save Bar
              Row(
                children: [
                  Expanded(
                    child: NeoBox(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: 12,
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          hintText: '# Paste link to quick save',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _quickSave(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  NeoButton(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 12,
                    color: AppTheme.secondary,
                    onPressed: _quickSave,
                    child: isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.border, strokeWidth: 3))
                      : const Icon(Icons.add, color: AppTheme.border, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Collections Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Collections',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder, size: 28),
                    onPressed: _showAddCollectionModal,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Collections Grid
              Expanded(
                child: collectionsAsync.when(
                  data: (collections) {
                    if (collections.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No collections yet.', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 16),
                            NeoButton(
                              color: AppTheme.accent,
                              onPressed: _showAddCollectionModal,
                              child: const Text('Create One', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      );
                    }
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: collections.length,
                      itemBuilder: (context, index) {
                        final col = collections[index];
                        return GestureDetector(
                          onTap: () => context.push('/collection/${col.id}', extra: col),
                          child: NeoBox(
                            color: Color(int.parse('0xFF${col.colorHex}')),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  IconData(col.iconCodePoint, fontFamily: col.iconFontFamily),
                                  size: 32,
                                ),
                                const Spacer(),
                                Text(
                                  col.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // We don't have the item count easily available without a stream or join, 
                                // so we can display a placeholder or leave it out for v1
                                const Text('View items', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
