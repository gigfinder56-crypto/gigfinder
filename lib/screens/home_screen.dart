import 'package:flutter/material.dart';
import 'package:mavenlink/models/user.dart' as app_models;
import 'package:mavenlink/models/opportunity.dart';
import 'package:mavenlink/services/auth_service.dart';
import 'package:mavenlink/services/user_service.dart';
import 'package:mavenlink/services/notification_service.dart';
import 'package:mavenlink/services/ml_recommendation_service.dart';
import 'package:mavenlink/screens/opportunities_screen.dart';
import 'package:mavenlink/screens/my_applications_screen.dart';
import 'package:mavenlink/screens/chat_screen.dart';
import 'package:mavenlink/screens/profile_screen.dart';
import 'package:mavenlink/screens/notifications_screen.dart';
import 'package:mavenlink/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final MLRecommendationService _mlRecommendationService = MLRecommendationService();

  int _currentIndex = 0;
  app_models.User? _currentUser;
  int _unreadNotifications = 0;
  bool _isLoading = true;
  RealtimeChannel? _appStatusChannel;
  RealtimeChannel? _notificationChannel;

  final List<String> _categories = [
    'Internships',
    'Projects',
    'Scholarships',
    'Hackathons',
    'Tuitions',
    'IT Jobs',
  ];

 final Map<String, IconData> _categoryIcons = {
  'Internships': Icons.work_outline,
  'Projects': Icons.code,
  'Scholarships': Icons.school,
  'Hackathons': Icons.lightbulb_outline,
  'Tuitions': Icons.person_outline,
  'IT Jobs': Icons.computer
};


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user != null) {
        final recommendations = await _mlRecommendationService.getRecommendationsForUser(user.id);
        await _ensureRecommendationNotifications(user.id, recommendations);
        final unreadCount = await _notificationService.getUnreadCount(user.id);

        setState(() {
          _currentUser = user;
          _unreadNotifications = unreadCount;
          _isLoading = false;
        });

        _startRealtimeSubscriptions(user.id);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _ensureRecommendationNotifications(String userId, List<Opportunity> recos) async {
    if (recos.isEmpty) return;
    try {
      final existing = await _notificationService.getUserNotifications(userId);
      final notifiedOppIds = existing
          .where((n) => n.type == 'recommendation' && n.opportunityId != null)
          .map((n) => n.opportunityId)
          .toSet();
      for (final opp in recos.take(5)) {
        if (!notifiedOppIds.contains(opp.id)) {
          await _notificationService.sendNotification(
            userId: userId,
            title: 'New Match Found',
            message:
                'Based on your skills and location, ${opp.title} at ${opp.company} looks like a great fit.',
            type: 'recommendation',
            opportunityId: opp.id,
          );
        }
      }
    } catch (_) {}
  }

  void _startRealtimeSubscriptions(String userId) {
    _appStatusChannel ??= _notificationService.subscribeToApplicationStatusChanges(
      userId,
      onCreated: (_) async {
        final count = await _notificationService.getUnreadCount(userId);
        if (mounted) setState(() => _unreadNotifications = count);
      },
    );

    _notificationChannel ??= Supabase.instance.client
        .channel('public:notifications:user:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) async {
            final rec = payload.newRecord;
            if (rec['user_id'] != userId) return;
            final count = await _notificationService.getUnreadCount(userId);
            if (mounted) setState(() => _unreadNotifications = count);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_appStatusChannel != null) {
      Supabase.instance.client.removeChannel(_appStatusChannel!);
      _appStatusChannel = null;
    }
    if (_notificationChannel != null) {
      Supabase.instance.client.removeChannel(_notificationChannel!);
      _notificationChannel = null;
    }
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  void _navigateToOpportunities(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpportunitiesScreen(category: category),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screens = [
      _buildHomeTab(),
      const MyApplicationsScreen(),
      const ChatScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _currentIndex == 0
          ? AppBar(
              title: Text(
                'GigFinder',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              backgroundColor: colorScheme.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  onPressed: _logout,
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _navigateToNotifications,
              backgroundColor: colorScheme.primary,
              child: Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: colorScheme.onPrimary,
                  ),
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_unreadNotifications',
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    _currentUser?.name ?? 'User',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discover new opportunities today!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Only categories
            Text(
              'Browse Categories',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = _categoryIcons[category] ?? Icons.work;

    final gradients = [
      [colorScheme.primary, colorScheme.tertiary],
      [colorScheme.secondary, colorScheme.primary],
      [colorScheme.tertiary, colorScheme.secondary],
      [colorScheme.primary.withOpacity(0.8), colorScheme.tertiary.withOpacity(0.8)],
      [colorScheme.secondary.withOpacity(0.8), colorScheme.primary.withOpacity(0.8)],
      [colorScheme.tertiary.withOpacity(0.8), colorScheme.secondary.withOpacity(0.8)],
    ];

    final gradient = gradients[_categories.indexOf(category) % gradients.length];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToOpportunities(category),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: colorScheme.onPrimary,
              ),
              const SizedBox(height: 12),
              Text(
                category,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
