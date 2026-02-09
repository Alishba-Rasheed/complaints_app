import 'package:flutter/material.dart';
import '../../models/announcement_models.dart';
import '../../services/announcement_service.dart';

/// Screen to view applications for a specific announcement
class AnnouncementApplicationsScreen extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementApplicationsScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = AnnouncementService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Applications'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              announcement.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<AnnouncementApplication>>(
        stream: service.getApplications(announcement.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final applications = snapshot.data ?? [];

          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No applications yet', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            );
          }

          // Group by status
          final pending = applications.where((a) => a.status == ApplicationStatus.pending).toList();
          final approved = applications.where((a) => a.status == ApplicationStatus.approved).toList();
          final rejected = applications.where((a) => a.status == ApplicationStatus.rejected).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsRow(theme, pending.length, approved.length, rejected.length),
              const SizedBox(height: 24),
              if (pending.isNotEmpty) ...[
                _buildSectionHeader(theme, 'Pending', Icons.hourglass_empty, Colors.orange, pending.length),
                ...pending.map((app) => _ApplicationCard(application: app, announcement: announcement)),
              ],
              if (approved.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader(theme, 'Approved', Icons.check_circle, Colors.green, approved.length),
                ...approved.map((app) => _ApplicationCard(application: app, announcement: announcement)),
              ],
              if (rejected.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader(theme, 'Rejected', Icons.cancel, Colors.red, rejected.length),
                ...rejected.map((app) => _ApplicationCard(application: app, announcement: announcement)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, int pending, int approved, int rejected) {
    return Row(
      children: [
        _buildStatChip(theme, 'Pending', pending, Colors.orange),
        const SizedBox(width: 8),
        _buildStatChip(theme, 'Approved', approved, Colors.green),
        const SizedBox(width: 8),
        _buildStatChip(theme, 'Rejected', rejected, Colors.red),
      ],
    );
  }

  Widget _buildStatChip(ThemeData theme, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(count.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final AnnouncementApplication application;
  final Announcement announcement;

  const _ApplicationCard({required this.application, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = application.isPending ? Colors.orange : application.isApproved ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      application.userName.isNotEmpty ? application.userName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(application.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(application.userEmail, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    application.status.name.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  'Applied: ${_formatDate(application.appliedAt)}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
            if (application.notes != null && application.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        application.notes!,
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (application.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(context, ApplicationStatus.rejected),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(context, ApplicationStatus.approved),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _updateStatus(BuildContext context, ApplicationStatus status) async {
    try {
      await AnnouncementService().updateApplicationStatus(
        announcementId: announcement.id,
        applicationId: application.id,
        status: status,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status.name}'),
            backgroundColor: status == ApplicationStatus.approved ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}