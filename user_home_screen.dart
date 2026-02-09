import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/system_provider.dart';
import '../../widgets/clock_widget.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/language_switcher.dart';
import '../../services/chat_service.dart';
import '../../services/announcement_service.dart';
import '../../models/announcement_models.dart';
import '../../models/chat_models.dart';
import '../../l10n/app_localizations.dart';
import 'submit_complaint_screen.dart';
import 'my_complaints_screen.dart';
import 'contacts_screen.dart';
import 'announcements_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    debugPrint("INIT: UserHomeScreen started for user: ${context.read<AuthProvider>().user?.username}");
    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) {
        auth.fetchProfile().then((_) {
          if (mounted) {
            final updatedAuth = context.read<AuthProvider>();
            // Register user in Firebase for chat
            _registerUserInFirebase(updatedAuth);
          }
        });
      } else {
        // Register user in Firebase for chat
        _registerUserInFirebase(auth);
      }
      context.read<ComplaintProvider>().fetchCategories();
      context.read<SystemProvider>().fetchSettings();
    });
  }

  /// Register user in Firebase users collection for chat functionality
  Future<void> _registerUserInFirebase(AuthProvider auth) async {
    if (auth.user == null) return;
    
    try {
      final userParticipant = ChatParticipant(
        id: auth.user!.id.toString(),
        name: auth.user!.username,
        email: auth.user!.email ?? '',
        role: 'user',
        isOnline: true,
      );
      await _chatService.registerUser(userParticipant);
      debugPrint('User registered in Firebase: ${auth.user!.username}');
    } catch (e) {
      debugPrint('Error registering user in Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    final List<Widget> pages = [
      const UserHomeContent(),
      const MyComplaintsScreen(),
      ContactsScreen(
        currentUserId: auth.user?.id.toString() ?? '0',
        currentUserName: auth.user?.username ?? 'User',
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n?.home ?? 'Home'),
              NavigationDestination(icon: const Icon(Icons.history_outlined), selectedIcon: const Icon(Icons.history), label: l10n?.complaints ?? 'Complaints'),
              NavigationDestination(icon: const Icon(Icons.chat_outlined), selectedIcon: const Icon(Icons.chat), label: l10n?.chat ?? 'Chat'),
              NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n?.profile ?? 'Profile'),
            ],
          );
        },
      ),
    );
  }
}

class UserHomeContent extends StatefulWidget {
  const UserHomeContent({super.key});

  @override
  State<UserHomeContent> createState() => _UserHomeContentState();
}

class _UserHomeContentState extends State<UserHomeContent> {
  final AnnouncementService _announcementService = AnnouncementService();
  late final Stream<List<Announcement>> _announcementsStream;

  @override
  void initState() {
    super.initState();
    // Cache the stream so it doesn't get recreated on each rebuild
    _announcementsStream = _announcementService.getActiveAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final complaintProvider = context.watch<ComplaintProvider>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.complaintHub ?? 'Complaint Hub', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const CompactClockWidget(),
          const SizedBox(width: 8),
          const CompactLanguageSwitcher(),
          const SizedBox(width: 8),
          const AppBarThemeToggle(),
          const SizedBox(width: 8),
          _buildChatButton(context, auth),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: IconButton(
              onPressed: () => complaintProvider.fetchCategories(),
              icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
           final auth = context.read<AuthProvider>();
           if (auth.user == null) await auth.fetchProfile();
           await context.read<ComplaintProvider>().fetchCategories();
           await context.read<SystemProvider>().fetchSettings();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Card with Clock
              _buildProfileCard(context, auth, theme),
              const SizedBox(height: 24),
              
              // Theme Settings Card
              const ThemeToggle(),
              const SizedBox(height: 32),
              
              Text(l10n?.quickActions ?? 'QUICK ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1.5)),
              const SizedBox(height: 20),

              _buildActionCard(
                context,
                title: l10n?.fileComplaint ?? 'File a Complaint',
                subtitle: l10n?.directReporting ?? 'Direct reporting to authorities',
                icon: Icons.add_comment_rounded,
                colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitComplaintScreen())),
              ),
              const SizedBox(height: 16),
              
              _buildActionCard(
                context,
                title: l10n?.chatWithAdmin ?? 'Chat with Admin',
                subtitle: l10n?.connectSupport ?? 'Connect with support team',
                icon: Icons.chat_bubble_rounded,
                colors: [const Color(0xFF10B981), const Color(0xFF34D399)],
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (_) => ChatListScreen(
                      currentUserId: auth.user?.id.toString() ?? '0',
                      currentUserName: auth.user?.username ?? 'User',
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              // Official Announcements Section
              _buildAnnouncementsSection(context, theme),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n?.supportCenter ?? 'Support Center', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface, letterSpacing: -0.5)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(l10n?.active247 ?? '24/7 ACTIVE', style: TextStyle(color: theme.colorScheme.primary, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<SystemProvider>(
                builder: (context, system, _) {
                  final s = system.settings;
                  return Column(
                    children: [
                      if (s.helpText.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface, 
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)), 
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(s.helpText, style: TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                        ),
                      _SupportOption(
                        icon: Icons.help_outline_rounded, 
                        title: 'FAQ & Help', 
                        color: Colors.blueAccent,
                        onTap: () => _launchURL(context, s.faqUrl),
                      ),
                      const SizedBox(height: 12),
                      _SupportOption(
                        icon: Icons.phone_in_talk_rounded, 
                        title: 'Contact Support', 
                        color: Colors.green,
                        subtitle: s.supportNumber,
                        onTap: () => _launchURL(context, 'tel:${s.supportNumber}'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthProvider auth, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
                Text(
                  auth.user?.username ?? 'Guest User',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'USER',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton(BuildContext context, AuthProvider auth) {
    return StreamBuilder<int>(
      stream: ChatService().getTotalUnreadCount(auth.user?.id.toString() ?? '0'),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        final theme = Theme.of(context);
        
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatListScreen(
                      currentUserId: auth.user?.id.toString() ?? '0',
                      currentUserName: auth.user?.username ?? 'User',
                    ),
                  ),
                ),
                icon: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required List<Color> colors, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: colors.first.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    if (url.isEmpty || url == '#' || url == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support link not set yet')));
      return;
    }

    String finalUrl = url;
    if (!url.startsWith('https://') && !url.startsWith('http://') && !url.startsWith('tel:')) {
      finalUrl = 'https://$url';
    }

    try {
      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    } catch (e) {
      debugPrint("Launch URL Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid link format')));
    }
  }

  Widget _buildAnnouncementsSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF472B6)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Official Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: StreamBuilder<List<Announcement>>(
            stream: _announcementsStream, // Use cached stream from initState
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final announcements = snapshot.data ?? [];
              if (announcements.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text('No announcements', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: announcements.length.clamp(0, 5),
                itemBuilder: (context, index) => _buildAnnouncementMiniCard(context, theme, announcements[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementMiniCard(BuildContext context, ThemeData theme, Announcement announcement) {
    final colors = _getAnnouncementColors(announcement.type);
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors[0].withValues(alpha: 0.1), colors[1].withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors[0].withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${announcement.typeEmoji} ${announcement.typeLabel}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  if (announcement.allowApplications)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('OPEN', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                announcement.title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    '${announcement.applicationCount} applied',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getAnnouncementColors(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.event: return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      case AnnouncementType.scheme: return [const Color(0xFF10B981), const Color(0xFF34D399)];
      case AnnouncementType.notice: return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case AnnouncementType.general: return [const Color(0xFF6366F1), const Color(0xFF818CF8)];
    }
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _SupportOption({
    required this.icon, 
    required this.title, 
    this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}