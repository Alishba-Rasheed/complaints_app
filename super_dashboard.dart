import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/system_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/app_models.dart';
import '../../models/chat_models.dart';
import '../../widgets/clock_widget.dart';
import '../../widgets/theme_toggle.dart';
import '../../services/chat_service.dart';
import 'super_control_hub.dart';
import 'super_all_complaints_screen.dart';
import 'super_chat_screen.dart';
import 'manage_announcements_screen.dart';
import '../profile_screen.dart';

class SuperDashboard extends StatefulWidget {
  const SuperDashboard({super.key});

  @override
  State<SuperDashboard> createState() => _SuperDashboardState();
}

class _SuperDashboardState extends State<SuperDashboard> {
  int _selectedIndex = 0;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) {
        auth.fetchProfile().then((_) {
          if (mounted) {
            final updatedAuth = context.read<AuthProvider>();
            // Register super admin in Firebase for chat
            _registerSuperAdminInFirebase(updatedAuth);
          }
        });
      } else {
        // Register super admin in Firebase for chat
        _registerSuperAdminInFirebase(auth);
      }
      context.read<ComplaintProvider>().fetchAllComplaints();
      context.read<ComplaintProvider>().fetchCategories();
      
      // Start real-time watchers for Hub consistency
      context.read<ComplaintProvider>().startWatchingCategories();
      context.read<SystemProvider>().startWatchingSettings();
    });
  }

  /// Register super admin user in Firebase users collection for chat functionality
  Future<void> _registerSuperAdminInFirebase(AuthProvider auth) async {
    if (auth.user == null) return;
    
    try {
      final superAdminParticipant = ChatParticipant(
        id: auth.user!.id.toString(),
        name: auth.user!.username,
        email: auth.user!.email ?? '',
        role: 'super admin', // Always super admin for this dashboard
        isOnline: true,
      );
      await _chatService.registerUser(superAdminParticipant);
      debugPrint('Super Admin registered in Firebase: ${auth.user!.username}');
    } catch (e) {
      debugPrint('Error registering super admin in Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    
    final List<Widget> pages = [
      const SuperStatsContent(),
      const SuperControlHub(),
      const SuperAllComplaintsScreen(),
      const ManageAnnouncementsScreen(),
      SuperChatScreen(
        currentUserId: auth.user?.id.toString() ?? '0',
        currentUserName: auth.user?.username ?? 'Super Admin',
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: theme.colorScheme.surface,
            elevation: null,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.none,
            groupAlignment: -0.8,
            useIndicator: true,
            indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            selectedIconTheme: IconThemeData(color: theme.colorScheme.primary, size: 28),
            unselectedIconTheme: IconThemeData(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 24),
            destinations: [
              const NavigationRailDestination(icon: Icon(Icons.grid_view_rounded), label: Text('Home')),
              const NavigationRailDestination(icon: Icon(Icons.shield_rounded), label: Text('Control Hub')),
              const NavigationRailDestination(icon: Icon(Icons.dns_rounded), label: Text('Activity')),
              const NavigationRailDestination(icon: Icon(Icons.campaign_rounded), label: Text('Announcements')),
              NavigationRailDestination(
                icon: _buildChatBadge(auth),
                selectedIcon: _buildChatBadge(auth, selected: true),
                label: const Text('Chat'),
              ),
              const NavigationRailDestination(icon: Icon(Icons.manage_accounts_rounded), label: Text('Profile')),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1, color: theme.dividerColor),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBadge(AuthProvider auth, {bool selected = false}) {
    return StreamBuilder<int>(
      stream: ChatService().getTotalUnreadCount(auth.user?.id.toString() ?? '0'),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(selected ? Icons.chat : Icons.chat_outlined),
            if (count > 0)
              Positioned(
                right: -8,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SuperStatsContent extends StatelessWidget {
  const SuperStatsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final complaintProvider = context.watch<ComplaintProvider>();
    final recentComplaints = complaintProvider.complaints.take(8).toList();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('SYSTEM CONTROL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const CompactClockWidget(),
          const SizedBox(width: 8),
          const AppBarThemeToggle(),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
            ),
            child: IconButton(
              onPressed: () {
                complaintProvider.fetchAllComplaints();
                complaintProvider.fetchCategories();
              },
              icon: Icon(Icons.sync_rounded, color: theme.colorScheme.primary, size: 20),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await complaintProvider.fetchAllComplaints();
          await complaintProvider.fetchCategories();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF818CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 12)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              const Text('SYSTEM LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.bolt_rounded, color: Colors.white.withOpacity(0.4), size: 20),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Global Command', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
                    const Text('Center', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 0.8, letterSpacing: -1.5)),
                    const SizedBox(height: 12),
                    Text('Orchestrating system operations and intelligence', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3, // Increased to prevent overflow
                children: [
                  _GlobalStatCard(title: 'Issues', value: complaintProvider.complaints.length.toString(), icon: Icons.description_rounded, color: const Color(0xFF6366F1)),
                  _GlobalStatCard(title: 'Scope', value: complaintProvider.categories.length.toString(), icon: Icons.hub_rounded, color: const Color(0xFF8B5CF6)),
                  _GlobalStatCard(title: 'Open', value: complaintProvider.complaints.where((c)=>c.status=='pending').length.toString(), icon: Icons.hourglass_empty_rounded, color: const Color(0xFFF59E0B)),
                  _GlobalStatCard(title: 'Fixed', value: complaintProvider.complaints.where((c)=>c.status=='resolved').length.toString(), icon: Icons.verified_rounded, color: const Color(0xFF10B981)),
                ],
              ),

              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Global Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  TextButton(
                    onPressed: () {}, // Navigate to feed
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (complaintProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (recentComplaints.isEmpty)
                _EmptyState()
              else
                ...recentComplaints.map((c) => _GlobalComplaintItem(complaint: c)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _GlobalStatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [BoxShadow(color: Colors.blueGrey.shade900.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.blueGrey.shade500, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }
}

class _GlobalComplaintItem extends StatelessWidget {
  final Complaint complaint;
  const _GlobalComplaintItem({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade50),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (complaint.status == 'resolved' ? Colors.green : Colors.blue).withOpacity(0.1),
            child: Icon(complaint.status == 'resolved' ? Icons.check : Icons.priority_high, size: 18, color: complaint.status == 'resolved' ? Colors.green : Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('User #${complaint.userId} • Cat ${complaint.categoryId}', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
             Icon(Icons.auto_graph_rounded, size: 64, color: Colors.blueGrey.shade200),
             const SizedBox(height: 16),
             Text('No system activity recorded yet.', style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}