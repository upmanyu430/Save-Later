import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_constants.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_button.dart';
import '../../models/collection.dart';

class IconItem {
  final IconData icon;
  final String name;
  final String category;
  final List<String> keywords;

  const IconItem({
    required this.icon,
    required this.name,
    required this.category,
    this.keywords = const [],
  });
}

class IconPickerScreen extends StatefulWidget {
  final String selectedColorHex;
  final int currentIconCode;

  const IconPickerScreen({
    super.key,
    required this.selectedColorHex,
    required this.currentIconCode,
  });

  @override
  State<IconPickerScreen> createState() => _IconPickerScreenState();
}

class _IconPickerScreenState extends State<IconPickerScreen> {
  late TextEditingController _searchController;
  late int _selectedIconCode;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  static const List<String> _categories = [
    'All',
    'Essentials',
    'Travel',
    'Tech & Code',
    'Work & Study',
    'Media & Art',
    'Food & Drink',
    'Shopping',
    'Sports & Health',
    'Nature & Space',
  ];

  static final List<IconItem> _allIcons = [
    // Essentials
    IconItem(icon: Icons.folder_outlined, name: 'Folder', category: 'Essentials', keywords: ['directory', 'files', 'archive', 'storage']),
    IconItem(icon: Icons.star_outline, name: 'Star', category: 'Essentials', keywords: ['favorite', 'rate', 'best', 'featured']),
    IconItem(icon: Icons.favorite_outline, name: 'Heart', category: 'Essentials', keywords: ['love', 'like', 'health', 'favorite']),
    IconItem(icon: Icons.bookmark_border, name: 'Bookmark', category: 'Essentials', keywords: ['save', 'ribbon', 'mark', 'read']),
    IconItem(icon: Icons.bookmark_added_outlined, name: 'Saved', category: 'Essentials', keywords: ['bookmark', 'checked', 'done']),
    IconItem(icon: Icons.home_outlined, name: 'Home', category: 'Essentials', keywords: ['house', 'main', 'start']),
    IconItem(icon: Icons.flag_outlined, name: 'Flag', category: 'Essentials', keywords: ['goal', 'milestone', 'country', 'priority']),
    IconItem(icon: Icons.lightbulb_outline, name: 'Lightbulb', category: 'Essentials', keywords: ['idea', 'tip', 'inspire', 'thought', 'bright']),
    IconItem(icon: Icons.notifications_none, name: 'Bell', category: 'Essentials', keywords: ['alert', 'notification', 'reminder']),
    IconItem(icon: Icons.push_pin_outlined, name: 'Pin', category: 'Essentials', keywords: ['pushpin', 'tack', 'attach', 'sticky', 'board']),
    IconItem(icon: Icons.tag, name: 'Tag', category: 'Essentials', keywords: ['hash', 'topic', 'label', 'keyword']),
    IconItem(icon: Icons.label_outline, name: 'Label', category: 'Essentials', keywords: ['tag', 'badge', 'ticket']),
    IconItem(icon: Icons.search, name: 'Search', category: 'Essentials', keywords: ['find', 'lookup', 'magnifier', 'explore']),
    IconItem(icon: Icons.lock_outline, name: 'Lock', category: 'Essentials', keywords: ['secure', 'private', 'password', 'key']),
    IconItem(icon: Icons.vpn_key_outlined, name: 'Key', category: 'Essentials', keywords: ['unlock', 'access', 'secret', 'password']),
    IconItem(icon: Icons.shield_outlined, name: 'Shield', category: 'Essentials', keywords: ['security', 'guard', 'protect', 'safe']),
    IconItem(icon: Icons.check_circle_outline, name: 'Check', category: 'Essentials', keywords: ['done', 'complete', 'success', 'verified']),
    IconItem(icon: Icons.help_outline, name: 'Help', category: 'Essentials', keywords: ['question', 'faq', 'support', 'ask']),
    IconItem(icon: Icons.info_outline, name: 'Info', category: 'Essentials', keywords: ['about', 'details', 'notice']),
    IconItem(icon: Icons.visibility_outlined, name: 'Eye', category: 'Essentials', keywords: ['view', 'look', 'watch', 'vision']),

    // Travel
    IconItem(icon: Icons.flight_takeoff, name: 'Airplane', category: 'Travel', keywords: ['flight', 'fly', 'trip', 'travel', 'vacation']),
    IconItem(icon: Icons.flight_land, name: 'Landing', category: 'Travel', keywords: ['arrive', 'airport', 'plane']),
    IconItem(icon: Icons.directions_car_outlined, name: 'Car', category: 'Travel', keywords: ['drive', 'automobile', 'vehicle', 'road', 'trip']),
    IconItem(icon: Icons.train_outlined, name: 'Train', category: 'Travel', keywords: ['railway', 'subway', 'metro', 'transit']),
    IconItem(icon: Icons.directions_boat_outlined, name: 'Boat', category: 'Travel', keywords: ['ship', 'cruise', 'sea', 'ocean', 'ferry']),
    IconItem(icon: Icons.directions_bike_outlined, name: 'Bicycle', category: 'Travel', keywords: ['bike', 'cycling', 'ride']),
    IconItem(icon: Icons.directions_bus_outlined, name: 'Bus', category: 'Travel', keywords: ['transit', 'commute', 'public']),
    IconItem(icon: Icons.public, name: 'Globe', category: 'Travel', keywords: ['world', 'earth', 'international', 'planet', 'web']),
    IconItem(icon: Icons.location_on_outlined, name: 'Location', category: 'Travel', keywords: ['pin', 'place', 'map', 'gps', 'destination']),
    IconItem(icon: Icons.map_outlined, name: 'Map', category: 'Travel', keywords: ['guide', 'navigation', 'journey', 'atlas']),
    IconItem(icon: Icons.explore_outlined, name: 'Compass', category: 'Travel', keywords: ['explore', 'direction', 'adventure']),
    IconItem(icon: Icons.hotel_outlined, name: 'Hotel', category: 'Travel', keywords: ['stay', 'bed', 'hostel', 'resort', 'motel']),
    IconItem(icon: Icons.luggage_outlined, name: 'Luggage', category: 'Travel', keywords: ['suitcase', 'baggage', 'pack', 'travel']),
    IconItem(icon: Icons.beach_access_outlined, name: 'Beach', category: 'Travel', keywords: ['vacation', 'holiday', 'resort', 'umbrella', 'summer']),
    IconItem(icon: Icons.castle_outlined, name: 'Castle', category: 'Travel', keywords: ['landmark', 'monument', 'history', 'tour']),

    // Tech & Code
    IconItem(icon: Icons.code, name: 'Code', category: 'Tech & Code', keywords: ['dev', 'html', 'css', 'programming', 'script', 'source']),
    IconItem(icon: Icons.terminal, name: 'Terminal', category: 'Tech & Code', keywords: ['console', 'bash', 'shell', 'cli', 'command']),
    IconItem(icon: Icons.desktop_windows_outlined, name: 'Desktop', category: 'Tech & Code', keywords: ['computer', 'pc', 'monitor', 'screen']),
    IconItem(icon: Icons.laptop_mac, name: 'Laptop', category: 'Tech & Code', keywords: ['macbook', 'notebook', 'computer', 'apple']),
    IconItem(icon: Icons.phone_outlined, name: 'Phone', category: 'Tech & Code', keywords: ['mobile', 'smartphone', 'cell', 'android', 'ios']),
    IconItem(icon: Icons.tablet_mac_outlined, name: 'Tablet', category: 'Tech & Code', keywords: ['ipad', 'pad', 'device']),
    IconItem(icon: Icons.developer_board, name: 'Circuit', category: 'Tech & Code', keywords: ['chip', 'hardware', 'arduino', 'raspberry', 'electronics']),
    IconItem(icon: Icons.memory, name: 'Memory', category: 'Tech & Code', keywords: ['ram', 'chip', 'cpu', 'hardware']),
    IconItem(icon: Icons.storage_outlined, name: 'Database', category: 'Tech & Code', keywords: ['server', 'sql', 'disk', 'drive', 'data']),
    IconItem(icon: Icons.cloud_outlined, name: 'Cloud', category: 'Tech & Code', keywords: ['aws', 'hosting', 'network', 'online']),
    IconItem(icon: Icons.wifi, name: 'WiFi', category: 'Tech & Code', keywords: ['internet', 'wireless', 'network', 'connection']),
    IconItem(icon: Icons.dns_outlined, name: 'Server', category: 'Tech & Code', keywords: ['dns', 'host', 'cluster', 'node']),
    IconItem(icon: Icons.data_object, name: 'Data Object', category: 'Tech & Code', keywords: ['json', 'object', 'data', 'api']),
    IconItem(icon: Icons.smart_toy_outlined, name: 'AI Robot', category: 'Tech & Code', keywords: ['bot', 'ai', 'robot', 'automation', 'machine']),
    IconItem(icon: Icons.bug_report_outlined, name: 'Bug', category: 'Tech & Code', keywords: ['error', 'defect', 'issue', 'debug', 'fix']),
    IconItem(icon: Icons.fingerprint, name: 'Biometric', category: 'Tech & Code', keywords: ['fingerprint', 'security', 'auth', 'identity']),

    // Work & Study
    IconItem(icon: Icons.work_outline, name: 'Briefcase', category: 'Work & Study', keywords: ['job', 'career', 'office', 'business', 'work']),
    IconItem(icon: Icons.school_outlined, name: 'Graduation', category: 'Work & Study', keywords: ['school', 'education', 'college', 'university', 'study']),
    IconItem(icon: Icons.menu_book, name: 'Book', category: 'Work & Study', keywords: ['reading', 'novel', 'manual', 'guide', 'literature']),
    IconItem(icon: Icons.calendar_today_outlined, name: 'Calendar', category: 'Work & Study', keywords: ['date', 'schedule', 'event', 'appointment']),
    IconItem(icon: Icons.access_time, name: 'Clock', category: 'Work & Study', keywords: ['time', 'watch', 'hour', 'timer', 'history']),
    IconItem(icon: Icons.edit_note, name: 'Note', category: 'Work & Study', keywords: ['memo', 'text', 'draft', 'write']),
    IconItem(icon: Icons.assignment_outlined, name: 'Clipboard', category: 'Work & Study', keywords: ['tasks', 'homework', 'checklist', 'audit']),
    IconItem(icon: Icons.task_alt, name: 'Tasks', category: 'Work & Study', keywords: ['todo', 'completed', 'checklist', 'goals']),
    IconItem(icon: Icons.description_outlined, name: 'Document', category: 'Work & Study', keywords: ['file', 'doc', 'paper', 'pdf', 'article']),
    IconItem(icon: Icons.inventory_2_outlined, name: 'Box', category: 'Work & Study', keywords: ['package', 'parcel', 'archive', 'stock']),
    IconItem(icon: Icons.attach_file, name: 'Paperclip', category: 'Work & Study', keywords: ['attach', 'file', 'link']),
    IconItem(icon: Icons.calculate_outlined, name: 'Calculator', category: 'Work & Study', keywords: ['math', 'finance', 'numbers', 'accounting']),
    IconItem(icon: Icons.science_outlined, name: 'Science', category: 'Work & Study', keywords: ['chemistry', 'flask', 'experiment', 'lab', 'research']),
    IconItem(icon: Icons.architecture, name: 'Architecture', category: 'Work & Study', keywords: ['ruler', 'design', 'blueprint', 'measure', 'draft']),

    // Media & Art
    IconItem(icon: Icons.music_note_outlined, name: 'Music', category: 'Media & Art', keywords: ['song', 'tune', 'audio', 'melody']),
    IconItem(icon: Icons.headphones_outlined, name: 'Headphones', category: 'Media & Art', keywords: ['audio', 'listen', 'podcast', 'music', 'sound']),
    IconItem(icon: Icons.movie_outlined, name: 'Movie', category: 'Media & Art', keywords: ['film', 'cinema', 'video', 'theatre', 'show']),
    IconItem(icon: Icons.camera_alt_outlined, name: 'Camera', category: 'Media & Art', keywords: ['photo', 'picture', 'snapshot', 'photography']),
    IconItem(icon: Icons.videocam_outlined, name: 'Videocam', category: 'Media & Art', keywords: ['video', 'record', 'broadcast', 'stream']),
    IconItem(icon: Icons.palette_outlined, name: 'Palette', category: 'Media & Art', keywords: ['art', 'color', 'paint', 'design', 'drawing']),
    IconItem(icon: Icons.brush_outlined, name: 'Brush', category: 'Media & Art', keywords: ['paint', 'art', 'canvas', 'illustration']),
    IconItem(icon: Icons.photo_outlined, name: 'Photo', category: 'Media & Art', keywords: ['picture', 'image', 'gallery', 'wallpaper']),
    IconItem(icon: Icons.mic_outlined, name: 'Microphone', category: 'Media & Art', keywords: ['voice', 'record', 'audio', 'sing', 'podcast']),
    IconItem(icon: Icons.radio_outlined, name: 'Radio', category: 'Media & Art', keywords: ['broadcast', 'fm', 'podcast', 'audio']),
    IconItem(icon: Icons.album_outlined, name: 'Vinyl', category: 'Media & Art', keywords: ['album', 'record', 'disc', 'music']),
    IconItem(icon: Icons.tv, name: 'TV', category: 'Media & Art', keywords: ['television', 'screen', 'stream', 'display']),
    IconItem(icon: Icons.theater_comedy_outlined, name: 'Theatre', category: 'Media & Art', keywords: ['drama', 'acting', 'performance', 'show']),

    // Food & Drink
    IconItem(icon: Icons.local_cafe_outlined, name: 'Coffee', category: 'Food & Drink', keywords: ['tea', 'cafe', 'espresso', 'mug', 'cup', 'drink', 'beverage']),
    IconItem(icon: Icons.restaurant_outlined, name: 'Restaurant', category: 'Food & Drink', keywords: ['food', 'dining', 'dinner', 'cutlery', 'fork', 'meal']),
    IconItem(icon: Icons.local_bar_outlined, name: 'Cocktail', category: 'Food & Drink', keywords: ['bar', 'drink', 'alcohol', 'martini', 'pub']),
    IconItem(icon: Icons.fastfood_outlined, name: 'Fast Food', category: 'Food & Drink', keywords: ['burger', 'snack', 'fries', 'meal']),
    IconItem(icon: Icons.local_pizza_outlined, name: 'Pizza', category: 'Food & Drink', keywords: ['slice', 'cheese', 'italian', 'food']),
    IconItem(icon: Icons.cake_outlined, name: 'Cake', category: 'Food & Drink', keywords: ['birthday', 'dessert', 'sweet', 'bakery', 'celebration']),
    IconItem(icon: Icons.icecream_outlined, name: 'Ice Cream', category: 'Food & Drink', keywords: ['gelato', 'dessert', 'cone', 'cold', 'sweet']),
    IconItem(icon: Icons.bakery_dining_outlined, name: 'Bakery', category: 'Food & Drink', keywords: ['bread', 'pastry', 'croissant', 'bake']),
    IconItem(icon: Icons.ramen_dining_outlined, name: 'Ramen', category: 'Food & Drink', keywords: ['noodles', 'soup', 'bowl', 'asian', 'food']),
    IconItem(icon: Icons.lunch_dining_outlined, name: 'Burger', category: 'Food & Drink', keywords: ['lunch', 'sandwich', 'meat', 'dinner']),
    IconItem(icon: Icons.sports_bar_outlined, name: 'Beer', category: 'Food & Drink', keywords: ['drink', 'alcohol', 'pint', 'pub', 'brew']),
    IconItem(icon: Icons.liquor_outlined, name: 'Bottle', category: 'Food & Drink', keywords: ['wine', 'liquor', 'alcohol', 'drink']),

    // Shopping & Finance
    IconItem(icon: Icons.shopping_cart_outlined, name: 'Cart', category: 'Shopping', keywords: ['shopping', 'buy', 'ecommerce', 'checkout']),
    IconItem(icon: Icons.shopping_bag_outlined, name: 'Bag', category: 'Shopping', keywords: ['shopping', 'purchase', 'store', 'retail']),
    IconItem(icon: Icons.store_outlined, name: 'Store', category: 'Shopping', keywords: ['shop', 'market', 'boutique', 'merchant']),
    IconItem(icon: Icons.attach_money, name: 'Money', category: 'Shopping', keywords: ['dollar', 'cash', 'currency', 'price', 'cost', 'wealth']),
    IconItem(icon: Icons.credit_card_outlined, name: 'Card', category: 'Shopping', keywords: ['credit', 'debit', 'payment', 'visa', 'mastercard']),
    IconItem(icon: Icons.account_balance_outlined, name: 'Bank', category: 'Shopping', keywords: ['finance', 'institution', 'balance', 'capital']),
    IconItem(icon: Icons.account_balance_wallet_outlined, name: 'Wallet', category: 'Shopping', keywords: ['money', 'pay', 'crypto', 'savings']),
    IconItem(icon: Icons.savings_outlined, name: 'Piggy Bank', category: 'Shopping', keywords: ['savings', 'invest', 'budget', 'coin']),
    IconItem(icon: Icons.receipt_long_outlined, name: 'Receipt', category: 'Shopping', keywords: ['bill', 'invoice', 'tax', 'statement']),
    IconItem(icon: Icons.card_giftcard, name: 'Gift', category: 'Shopping', keywords: ['present', 'giftcard', 'box', 'holiday', 'birthday']),
    IconItem(icon: Icons.sell_outlined, name: 'Sale Tag', category: 'Shopping', keywords: ['discount', 'deal', 'offer', 'price', 'sell']),
    IconItem(icon: Icons.price_check_outlined, name: 'Price Check', category: 'Shopping', keywords: ['price', 'discount', 'bargain']),

    // Sports & Health
    IconItem(icon: Icons.sports_esports_outlined, name: 'Gaming', category: 'Sports & Health', keywords: ['controller', 'game', 'playstation', 'arcade', 'play']),
    IconItem(icon: Icons.fitness_center, name: 'Gym', category: 'Sports & Health', keywords: ['workout', 'weight', 'dumbbell', 'fitness', 'exercise']),
    IconItem(icon: Icons.sports_soccer_outlined, name: 'Soccer', category: 'Sports & Health', keywords: ['football', 'ball', 'match', 'sport']),
    IconItem(icon: Icons.sports_basketball_outlined, name: 'Basketball', category: 'Sports & Health', keywords: ['nba', 'ball', 'hoop', 'sport']),
    IconItem(icon: Icons.sports_tennis_outlined, name: 'Tennis', category: 'Sports & Health', keywords: ['racket', 'court', 'match', 'sport']),
    IconItem(icon: Icons.pool_outlined, name: 'Swimming', category: 'Sports & Health', keywords: ['pool', 'water', 'swim', 'dive']),
    IconItem(icon: Icons.directions_run_outlined, name: 'Run', category: 'Sports & Health', keywords: ['running', 'jog', 'marathon', 'athlete']),
    IconItem(icon: Icons.self_improvement_outlined, name: 'Meditation', category: 'Sports & Health', keywords: ['yoga', 'mindfulness', 'zen', 'calm', 'peace']),
    IconItem(icon: Icons.medical_services_outlined, name: 'Medical', category: 'Sports & Health', keywords: ['doctor', 'health', 'firstaid', 'hospital', 'medicine']),
    IconItem(icon: Icons.monitor_heart_outlined, name: 'Heartbeat', category: 'Sports & Health', keywords: ['pulse', 'ecg', 'cardio', 'health']),
    IconItem(icon: Icons.spa_outlined, name: 'Spa', category: 'Sports & Health', keywords: ['relax', 'wellness', 'massage', 'flower']),

    // Nature & Space
    IconItem(icon: Icons.wb_sunny_outlined, name: 'Sun', category: 'Nature & Space', keywords: ['sunny', 'summer', 'day', 'warm', 'bright']),
    IconItem(icon: Icons.nightlight_outlined, name: 'Moon', category: 'Nature & Space', keywords: ['night', 'dark', 'sleep', 'lunar']),
    IconItem(icon: Icons.eco_outlined, name: 'Leaf', category: 'Nature & Space', keywords: ['green', 'nature', 'plant', 'organic', 'eco', 'earth']),
    IconItem(icon: Icons.forest_outlined, name: 'Forest', category: 'Nature & Space', keywords: ['trees', 'woods', 'outdoor', 'park']),
    IconItem(icon: Icons.water_drop_outlined, name: 'Water Drop', category: 'Nature & Space', keywords: ['rain', 'liquid', 'aqua', 'drop']),
    IconItem(icon: Icons.thunderstorm_outlined, name: 'Storm', category: 'Nature & Space', keywords: ['lightning', 'thunder', 'rain', 'weather']),
    IconItem(icon: Icons.pets_outlined, name: 'Pets', category: 'Nature & Space', keywords: ['dog', 'cat', 'animal', 'paw', 'puppy']),
    IconItem(icon: Icons.bolt, name: 'Lightning', category: 'Nature & Space', keywords: ['bolt', 'flash', 'energy', 'power', 'electric', 'fast']),
    IconItem(icon: Icons.rocket_launch_outlined, name: 'Rocket', category: 'Nature & Space', keywords: ['space', 'launch', 'startup', 'fast', 'blast']),
    IconItem(icon: Icons.auto_awesome_outlined, name: 'Sparkles', category: 'Nature & Space', keywords: ['magic', 'stars', 'ai', 'awesome', 'shine']),
    IconItem(icon: Icons.diamond_outlined, name: 'Diamond', category: 'Nature & Space', keywords: ['gem', 'jewel', 'luxury', 'precious', 'crystal']),
    IconItem(icon: Icons.celebration_outlined, name: 'Celebration', category: 'Nature & Space', keywords: ['party', 'confetti', 'holiday', 'event', 'fun']),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedIconCode = widget.currentIconCode;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<IconItem> get _filteredIcons {
    return _allIcons.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      if (!matchesCategory) return false;

      if (_searchQuery.isEmpty) return true;

      final query = _searchQuery.toLowerCase();
      final nameMatches = item.name.toLowerCase().contains(query);
      final keywordMatches = item.keywords.any((kw) => kw.toLowerCase().contains(query));
      return nameMatches || keywordMatches;
    }).toList();
  }

  Color get _themeColor => BookmarkCollection.parseColor(widget.selectedColorHex);

  void _selectAndReturn(int iconCodePoint) {
    HapticFeedback.lightImpact();
    Navigator.pop(context, iconCodePoint);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIcons;
    final selectedColor = _themeColor;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingXl,
                vertical: AppDimensions.paddingMd,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: NeoButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      borderWidth: 2,
                      borderRadius: AppDimensions.radiusSm,
                      child: const Icon(Icons.arrow_back, size: AppDimensions.iconSizeMd),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingLg),
                  Expanded(
                    child: Text(
                      'Choose Icon',
                      style: GoogleFonts.gabarito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.border,
                      ),
                    ),
                  ),
                  // Current Selected Icon Preview
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(color: AppTheme.border, width: 2.5),
                    ),
                    child: Icon(
                      IconData(_selectedIconCode, fontFamily: 'MaterialIcons'),
                      size: 22,
                      color: AppTheme.border,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingXl,
                vertical: AppDimensions.paddingSm,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppTheme.border, width: 2),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search icons (e.g. food, star, car, code)...',
                    hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.border),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Category Chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXl),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isCatSelected = _selectedCategory == cat;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCatSelected ? AppTheme.border : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCatSelected ? Colors.white : AppTheme.border,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppDimensions.paddingSm),

            // Icons Grid View
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.border, width: 2),
                            ),
                            child: const Icon(Icons.search_off, size: 36, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No icons found',
                            style: GoogleFonts.gabarito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try a different search keyword or category',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final columnCount = (constraints.maxWidth / 62).floor().clamp(4, 8);

                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingXl,
                            vertical: AppDimensions.paddingMd,
                          ),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columnCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isSelected = _selectedIconCode == item.icon.codePoint;

                            return Tooltip(
                              message: item.name,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedIconCode = item.icon.codePoint;
                                  });
                                  _selectAndReturn(item.icon.codePoint);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? selectedColor : Colors.white,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                                    border: Border.all(
                                      color: AppTheme.border,
                                      width: isSelected ? 2.0 : 1.0,
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 24,
                                    color: isSelected &&
                                            BookmarkCollection.isWhiteIconColor(selectedColor)
                                        ? Colors.white
                                        : AppTheme.border,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            // Bottom "Select Icon" Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingXl,
                vertical: AppDimensions.paddingMd,
              ),
              child: Builder(
                builder: (context) {
                  final isDarkBtn =
                      BookmarkCollection.isWhiteIconColor(selectedColor);
                  final btnTextColor = isDarkBtn ? Colors.white : AppTheme.border;

                  return NeoButton(
                    onPressed: () => _selectAndReturn(_selectedIconCode),
                    color: selectedColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconData(_selectedIconCode, fontFamily: 'MaterialIcons'),
                            size: 20,
                            color: btnTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select Icon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: btnTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
