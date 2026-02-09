import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/app_models.dart';
import '../../models/chat_models.dart';
import '../../widgets/clock_widget.dart';
import '../../widgets/theme_toggle.dart';
import '../../services/chat_service.dart';
import 'admin_complaints_screen.dart';
import 'admin_chat_screen.dart';
import 'respond_screen.dart';
import '../profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
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
            context.read<ComplaintProvider>().fetchAdminComplaints(categoryId: updatedAuth.user?.categoryId);
            // Register admin in Firebase for chat
            _registerAdminInFirebase(updatedAuth);
          }
        });
      } else {
        context.read<ComplaintProvider>().fetchAdminComplaints(categoryId: auth.user?.categoryId);
        // Register admin in Firebase for chat
        _registerAdminInFirebase(auth);
      }
    });
  }

  /// Register admin user in Firebase users collection for chat functionality
  Future<void> _registerAdminInFirebase(AuthProvider auth) async {
    if (auth.user == null) return;
    
    try {
      final adminParticipant = ChatParticipant(
        id: auth.user!.id.toString(),
        name: auth.user!.username,
        email: auth.user!.email ?? '',
        role: auth.user!.role, // 'admin' or 'super_admin'
        isOnline: true,
      );
      await _chatService.registerUser(adminParticipant);
      debugPrint('Admin registered in Firebase: ${auth.user!.username}');
    } catch (e) {
      debugPrint('Error registering admin in Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    final List<Widget> pages = [
      const AdminDashboardContent(),
      const AdminComplaintsScreen(),
      AdminChatScreen(
        currentUserId: auth.user?.id.toString() ?? '0',
        currentUserName: auth.user?.username ?? 'Admin',
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          const NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Complaints'),
          NavigationDestination(
            icon: _buildChatBadge(auth),
            selectedIcon: _buildChatBadge(auth, selected: true),
            label: 'Chat',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
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
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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

class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final complaintProvider = context.watch<ComplaintProvider>();
    final recentComplaints = complaintProvider.complaints.take(5).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN HUB', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
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
              onPressed: () => complaintProvider.fetchAdminComplaints(categoryId: auth.user?.categoryId),
              icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary, size: 20),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => complaintProvider.fetchAdminComplaints(categoryId: auth.user?.categoryId),
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
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 12)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white10,
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${auth.user?.username ?? 'Admin'}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.user?.categoryId != null ? "Assigned to Category ${auth.user?.categoryId}" : "Global Administration Access",
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text('SYSTEM OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
              const SizedBox(height: 20),

              if (complaintProvider.error != null && complaintProvider.complaints.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(child: Text("Sync Error: ${complaintProvider.error}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                      TextButton(onPressed: () => complaintProvider.fetchAdminComplaints(), child: const Text('RETRY')),
                    ],
                  ),
                ),
              
              // Stats Row
              Row(
                children: [
                  _StatCard(
                    title: 'Requests',
                    count: complaintProvider.complaints.length.toString(),
                    icon: Icons.analytics_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    title: 'Pending',
                    count: complaintProvider.complaints.where((c) => c.status == 'pending').length.toString(),
                    icon: Icons.timer_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    title: 'Resolved',
                    count: complaintProvider.complaints.where((c) => c.status == 'resolved').length.toString(),
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Complaints',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                  ),
                  Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),

              if (complaintProvider.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (recentComplaints.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('No complaints yet', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ...recentComplaints.map((complaint) => _RecentComplaintCard(complaint: complaint)),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(count, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
            Text(title, style: TextStyle(color: Colors.blueGrey.shade500, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _RecentComplaintCard extends StatelessWidget {
  final Complaint complaint;
  const _RecentComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: (complaint.status == 'resolved' ? Colors.green : Colors.blue).withOpacity(0.1),
          child: Icon(
            complaint.status == 'resolved' ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: complaint.status == 'resolved' ? Colors.green : Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          complaint.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text('Ref: #${complaint.id}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(width: 8),
            _MiniStatusBadge(status: complaint.status),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RespondScreen(complaint: complaint)),
        ),
      ),
    );
  }
}

class _MiniStatusBadge extends StatelessWidget {
  final String status;
  const _MiniStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved': color = Colors.green; break;
      case 'pending': color = Colors.orange; break;
      default: color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }
}