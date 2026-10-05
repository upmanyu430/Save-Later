import re

with open('lib/ui/screens/bookmark_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add state variables
state_vars = r'''class _BookmarkDetailScreenState extends ConsumerState<BookmarkDetailScreen> {
  late Bookmark bookmark;
  late TextEditingController _notesController;'''

state_vars_new = '''class _BookmarkDetailScreenState extends ConsumerState<BookmarkDetailScreen> {
  late Bookmark bookmark;
  late TextEditingController _notesController;
  late TextEditingController _titleController;
  bool _isEditingTitle = false;'''
content = content.replace(state_vars, state_vars_new)

# 2. Add initState logic
init_state = r'''  void initState() {
    super.initState();
    bookmark = widget.bookmark;
    _notesController = TextEditingController(text: bookmark.description ?? '');
  }'''

init_state_new = '''  void initState() {
    super.initState();
    bookmark = widget.bookmark;
    _notesController = TextEditingController(text: bookmark.description ?? '');
    _titleController = TextEditingController(text: bookmark.title ?? bookmark.url);
  }'''
content = content.replace(init_state, init_state_new)

# 3. Add dispose
dispose_block = '''  @override
  void dispose() {
    _notesController.dispose();
    _titleController.dispose();
    super.dispose();
  }
'''
if 'void dispose()' not in content:
    # insert before build method
    content = content.replace('  @override\n  Widget build(BuildContext context)', dispose_block + '\n  @override\n  Widget build(BuildContext context)')


# 4. Replace the title row
old_title_row = r'''                        // Title & Edit Button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                bookmark.title ?? bookmark.url,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            NeoBox(
                              padding: const EdgeInsets.all(8),
                              borderRadius: 12,
                              borderWidth: 2.5,
                              child: const Icon(Icons.edit_outlined, size: 24),
                            ),
                          ],
                        ),'''

new_title_row = '''                        // Title & Edit Button
                        if (_isEditingTitle)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFFD166), width: 3),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: TextField(
                                  controller: _titleController,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                    color: Colors.black,
                                  ),
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isEditingTitle = false;
                                        _titleController.text = bookmark.title ?? bookmark.url;
                                      });
                                    },
                                    child: NeoBox(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      borderRadius: 12,
                                      borderWidth: 3,
                                      color: Colors.white,
                                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () async {
                                      final newTitle = _titleController.text.trim();
                                      if (newTitle.isNotEmpty) {
                                        bookmark.title = newTitle;
                                        await ref.read(repositoryProvider).updateBookmark(bookmark);
                                        ref.invalidate(bookmarksProvider);
                                        if (bookmark.collection.value != null) {
                                            ref.invalidate(collectionBookmarksProvider(bookmark.collection.value!.id));
                                        }
                                        ref.invalidate(unsortedBookmarksProvider);
                                        setState(() {
                                          _isEditingTitle = false;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEEEEE),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade600, width: 3),
                                      ),
                                      child: Text('Save', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.grey.shade600)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  bookmark.title ?? bookmark.url,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isEditingTitle = true;
                                  });
                                },
                                child: NeoBox(
                                  padding: const EdgeInsets.all(8),
                                  borderRadius: 12,
                                  borderWidth: 2.5,
                                  child: const Icon(Icons.edit_outlined, size: 24),
                                ),
                              ),
                            ],
                          ),'''

content_re = re.sub(old_title_row, new_title_row, content)

if content == content_re:
    print("Regex failed to match!")
else:
    with open('lib/ui/screens/bookmark_detail_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content_re)
    print("Replaced successfully!")
