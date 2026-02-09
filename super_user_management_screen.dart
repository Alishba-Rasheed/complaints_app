import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../models/chat_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../services/chat_service.dart';

class SuperUserManagementScreen extends StatefulWidget {
  const SuperUserManagementScreen({super.key});

  @override
  State<SuperUserManagementScreen> createState() => _SuperUserManagementScreenState();
}

class _SuperUserManagementScreenState extends State<SuperUserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search participants...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Admins'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildParticipantList(isAdmins: false),
              _buildParticipantList(isAdmins: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantList({required bool isAdmins}) {
    return StreamBuilder<List<ChatParticipant>>(
      stream: isAdmins ? _chatService.getAdmins() : _chatService.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var list = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          list = list.where((p) => 
            p.name.toLowerCase().contains(_searchQuery) || 
            p.email.toLowerCase().contains(_searchQuery)
          ).toList();
        }

        if (list.isEmpty) {
          return const Center(child: Text('No participants found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) => _buildParticipantCard(list[index], isAdmins),
        );
      },
    );
  }

  Widget _buildParticipantCard(ChatParticipant participant, bool isAdmin) {
    final theme = Theme.of(context);
    final authProvider = context.read<AuthProvider>();
    final isSuspended = participant.role == 'suspended';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(230),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(40)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAdmin 
                ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                : [const Color(0xFF3B82F6), const Color(0xFF2DD4BF)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(participant.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSuspended ? Colors.red.withAlpha(30) : Colors.green.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isSuspended ? 'SUSPENDED' : 'ACTIVE',
                style: TextStyle(
                  color: isSuspended ? Colors.red : Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(participant.email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(150))),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
              ),
              child: Text(
                'ROLE: ${participant.role.toUpperCase()}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          onSelected: (val) {
             if (val == 'promote') _handlePromote(participant);
             if (val == 'demote') _handleDemote(participant);
             if (val == 'suspend') _handleSuspend(participant, !isSuspended);
             if (val == 'remove') _showRemoveConfirmation(participant);
          },
          itemBuilder: (context) => [
            if (!isAdmin && !isSuspended)
              const PopupMenuItem(value: 'promote', child: Row(children: [Icon(Icons.shield_rounded, size: 20), SizedBox(width: 8), Text('Promote to Admin')])),
            if (isAdmin)
              const PopupMenuItem(value: 'demote', child: Row(children: [Icon(Icons.person_outline_rounded, size: 20), SizedBox(width: 8), Text('Demote to User')])),
            PopupMenuItem(
              value: 'suspend', 
              child: Row(children: [
                Icon(isSuspended ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 20), 
                const SizedBox(width: 8), 
                Text(isSuspended ? 'Unsuspend' : 'Suspend Account')
              ])
            ),
            const PopupMenuItem(
              value: 'remove', 
              child: Row(children: [
                Icon(Icons.delete_forever_rounded, size: 20, color: Colors.red), 
                const SizedBox(width: 8), 
                Text('Permanent Remove', style: TextStyle(color: Colors.red))
              ])
            ),
          ],
        ),
      ),
    );
  }

  void _handlePromote(ChatParticipant participant) async {
    final complaintProvider = context.read<ComplaintProvider>();
    final categories = complaintProvider.categories;
    final defaultCatId = categories.isNotEmpty ? categories.first.id : 1; // Fallback to 1 if no categories

    final success = await context.read<AuthProvider>().promoteUser(
      User(id: int.tryParse(participant.id), username: participant.name, email: participant.email, role: 'user'),
      defaultCatId
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '${participant.name} promoted to Admin successfully' : 'Failed to promote user'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _handleDemote(ChatParticipant participant) async {
    final success = await context.read<AuthProvider>().demoteUser(
      User(id: int.tryParse(participant.id), username: participant.name, email: participant.email, role: 'admin')
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '${participant.name} demoted to User' : 'Failed to demote'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  void _handleSuspend(ChatParticipant participant, bool suspend) async {
    final success = await context.read<AuthProvider>().suspendUser(
      User(id: int.tryParse(participant.id), username: participant.name, email: participant.email, role: participant.role),
      suspend
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '${participant.name} ${suspend ? "suspended" : "unsuspended"}' : 'Action failed'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  void _showRemoveConfirmation(ChatParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent Removal'),
        content: Text('Are you sure you want to remove ${participant.name} permanently? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<AuthProvider>().removeUser(
                User(id: int.tryParse(participant.id), username: participant.name, email: participant.email, role: participant.role)
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '${participant.name} removed' : 'Failed to remove'),
                    backgroundColor: success ? Colors.red : Colors.grey,
                  ),
                );
              }
            },
            child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}