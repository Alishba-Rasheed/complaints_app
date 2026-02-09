import 'package:flutter/material.dart';
import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';

/// Contacts screen showing admins and super admins for users to request chats
class ContactsScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const ContactsScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  late TabController _tabController;
  Map<String, String> _requestStatuses = {}; // receiverId -> status
  Map<String, String> _roomIds = {}; // receiverId -> roomId

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequestStatuses();
  }

  Future<void> _loadRequestStatuses() async {
    // Listen to chat requests
    _chatService.getSentRequests(widget.currentUserId).listen((requests) {
      if (mounted) {
        setState(() {
          for (var r in requests) {
            _requestStatuses[r.receiver.id] = r.status.name;
          }
        });
      }
    });

    // Listen to existing chat rooms
    _chatService.getChatRooms(widget.currentUserId).listen((rooms) {
      if (mounted) {
        setState(() {
          for (var room in rooms) {
            final otherParticipant = room.getOtherParticipant(widget.currentUserId);
            if (otherParticipant != null) {
              _roomIds[otherParticipant.id] = room.id;
              // If a room exists, consider it as accepted even if request doc is gone
              _requestStatuses[otherParticipant.id] = 'accepted';
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'Admins', icon: Icon(Icons.admin_panel_settings, size: 20)),
            Tab(text: 'Super Admins', icon: Icon(Icons.shield, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAdminsList(theme),
          _buildSuperAdminsList(theme),
        ],
      ),
    );
  }

  Widget _buildAdminsList(ThemeData theme) {
    return StreamBuilder<List<ChatParticipant>>(
      stream: _chatService.getAdmins(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final admins = snapshot.data ?? [];

        if (admins.isEmpty) {
          return _buildEmptyState(theme, 'No admins available', Icons.admin_panel_settings);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: admins.length,
          itemBuilder: (context, index) => _buildContactCard(theme, admins[index]),
        );
      },
    );
  }

  Widget _buildSuperAdminsList(ThemeData theme) {
    return StreamBuilder<List<ChatParticipant>>(
      stream: _chatService.getSuperAdmins(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final superAdmins = snapshot.data ?? [];

        if (superAdmins.isEmpty) {
          return _buildEmptyState(theme, 'No super admins available', Icons.shield);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: superAdmins.length,
          itemBuilder: (context, index) => _buildContactCard(theme, superAdmins[index], isSuperAdmin: true),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(ThemeData theme, ChatParticipant contact, {bool isSuperAdmin = false}) {
    final requestStatus = _requestStatuses[contact.id];
    final colors = isSuperAdmin
        ? [const Color(0xFFEF4444), const Color(0xFFF97316)]
        : [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  if (contact.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: colors.map((c) => c.withValues(alpha: 0.1)).toList()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isSuperAdmin ? 'Super Admin' : 'Admin',
                          style: TextStyle(
                            color: colors[0],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.email,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contact.isOnline ? 'Online' : 'Last seen ${_formatLastSeen(contact.lastSeen)}',
                    style: TextStyle(
                      color: contact.isOnline ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Action button
            _buildActionButton(theme, contact, requestStatus, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, ChatParticipant contact, String? status, List<Color> colors) {
    if (status == 'accepted' || _roomIds.containsKey(contact.id)) {
      return GestureDetector(
        onTap: () => _openChat(contact, existingRoomId: _roomIds[contact.id]),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
            ),
            SizedBox(width: 8),
            Text('Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _sendRequest(contact),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors[0].withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors[0].withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add, color: colors[0], size: 18),
            const SizedBox(width: 6),
            Text('Request', style: TextStyle(color: colors[0], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'unknown';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _sendRequest(ChatParticipant receiver) async {
    try {
      final sender = ChatParticipant(
        id: widget.currentUserId,
        name: widget.currentUserName,
        email: '', // Will be filled from auth
        role: 'user',
      );

      await _chatService.sendChatRequest(
        sender: sender,
        receiver: receiver,
        message: 'Hello, I would like to chat with you.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${receiver.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openChat(ChatParticipant contact, {String? existingRoomId}) async {
    if (existingRoomId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            roomId: existingRoomId,
            currentUserId: widget.currentUserId,
            currentUserName: widget.currentUserName,
            otherParticipant: contact,
          ),
        ),
      );
      return;
    }

    // Show loading while searching for room
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final roomId = await _chatService.getChatRoomIdBetweenUsers(
        widget.currentUserId,
        contact.id,
      );

      if (mounted) Navigator.pop(context); // Hide loading

      if (roomId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat room not found. Please try again later.')),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: roomId,
              currentUserId: widget.currentUserId,
              currentUserName: widget.currentUserName,
              otherParticipant: contact,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Hide loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening chat: $e')),
        );
      }
    }
  }
}