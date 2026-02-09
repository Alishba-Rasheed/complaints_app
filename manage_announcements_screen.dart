import 'package:flutter/material.dart';
import '../../models/announcement_models.dart';
import '../../services/announcement_service.dart';
import 'create_announcement_screen.dart';
import 'announcement_applications_screen.dart';

/// Super Admin screen to manage all announcements
class ManageAnnouncementsScreen extends StatelessWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = AnnouncementService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Announcement'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: StreamBuilder<List<Announcement>>(
        stream: service.getAllAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final announcements = snapshot.data ?? [];

          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 20),
                  const Text('No announcements yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('Create your first announcement', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) => _AnnouncementManageCard(announcement: announcements[index]),
          );
        },
      ),
    );
  }
}

class _AnnouncementManageCard extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementManageCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getTypeColors(announcement.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors[0].withValues(alpha: 0.1), colors[1].withValues(alpha: 0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${announcement.typeEmoji} ${announcement.typeLabel}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: announcement.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    announcement.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: announcement.isActive ? Colors.green : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAction(context, action),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(announcement.isActive ? Icons.visibility_off : Icons.visibility, size: 18),
                          const SizedBox(width: 8),
                          Text(announcement.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.description,
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(theme, Icons.people, '${announcement.applicationCount} applied'),
                    const SizedBox(width: 12),
                    if (announcement.deadline != null)
                      _buildInfoChip(
                        theme,
                        Icons.schedule,
                        announcement.isExpired ? 'Expired' : _formatDeadline(announcement.deadline!),
                        isWarning: announcement.isExpired,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AnnouncementApplicationsScreen(announcement: announcement)),
                    ),
                    icon: const Icon(Icons.assignment, size: 18),
                    label: const Text('View Applications'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors[0],
                      side: BorderSide(color: colors[0]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String text, {bool isWarning = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isWarning ? Colors.red : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isWarning ? Colors.red : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, String action) async {
    final service = AnnouncementService();
    
    if (action == 'toggle') {
      await service.toggleAnnouncementStatus(announcement.id, !announcement.isActive);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Announcement ${announcement.isActive ? "deactivated" : "activated"}')),
        );
      }
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Announcement?'),
          content: const Text('This will delete all applications. This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        await service.deleteAnnouncement(announcement.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _formatDeadline(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return 'Ending soon';
  }

  List<Color> _getTypeColors(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.event: return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      case AnnouncementType.scheme: return [const Color(0xFF10B981), const Color(0xFF34D399)];
      case AnnouncementType.notice: return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case AnnouncementType.general: return [const Color(0xFF6366F1), const Color(0xFF818CF8)];
    }
  }
}