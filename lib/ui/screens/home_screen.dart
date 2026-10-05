import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../providers/providers.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import '../widgets/folder_box.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    
    // For sharing or opening url/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.type == SharedMediaType.text) {
         final text = value.first.path;
         _urlController.text = text;
         _quickSave();
      }
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing or opening url/text coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.type == SharedMediaType.text) {
         final text = value.first.path;
         _urlController.text = text;
         _quickSave();
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _urlController.dispose();
    super.dispose();
  }

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
    ref.listen(bookmarkNotifierProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) {
        if (next.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error saving link!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link saved! Tap the cards icon to review and organize it.')),
          );
        }
      }
    });

    final collectionsAsync = ref.watch(collectionsProvider);
    final isSaving = ref.watch(bookmarkNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NeoBox(
                    padding: const EdgeInsets.all(8),
                    borderRadius: 8,
                    borderWidth: 2.5,
                    child: const Icon(Icons.settings_outlined, size: 28),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showAddCollectionModal,
                        child: NeoBox(
                          padding: const EdgeInsets.all(8),
                          borderRadius: 8,
                          borderWidth: 2.5,
                          child: const Icon(Icons.create_new_folder_outlined, size: 28),
                        ),
                      ),
                      const SizedBox(width: 8),
                      NeoBox(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 8,
                        borderWidth: 2.5,
                        child: const Icon(Icons.search, size: 28),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Save now.\nFind anytime.',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1,
                ),
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
                        decoration: InputDecoration(
                          hintText: '#   Paste link to quick save',
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste_outlined, color: AppTheme.border),
                            onPressed: () async {
                              // Optional: Add clipboard pasting logic here
                            },
                          ),
                        ),
                        onSubmitted: (_) => _quickSave(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeoButton(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 12,
                    color: AppTheme.accent, // Yellow button
                    onPressed: _quickSave,
                    child: isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.border, strokeWidth: 3))
                      : const Icon(Icons.add, color: AppTheme.border, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Collections Header
              const Text(
                'My Collections',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Collections Grid
              Expanded(
                child: collectionsAsync.when(
                  data: (collections) {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 24, // Extra space for the folder tabs
                        childAspectRatio: 0.95,
                      ),
                      itemCount: collections.length + 1, // +1 for Unsorted
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Unsorted Folder
                          return FolderBox(
                            title: 'Unsorted',
                            itemCountText: 'View items',
                            folderColor: Colors.grey.shade400,
                            onTap: () => context.push('/review'),
                          );
                        }
                        
                        final col = collections[index - 1];
                        return Consumer(
                          builder: (context, ref, _) {
                            final countAsync = ref.watch(collectionBookmarksProvider(col.id));
                            final count = countAsync.valueOrNull?.length ?? 0;
                            return FolderBox(
                              title: col.name,
                              itemCountText: '$count items',
                              folderColor: col.color,
                              onTap: () => context.push('/collection/${col.id}', extra: col),
                            );
                          }
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
