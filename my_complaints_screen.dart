import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../models/app_models.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      if (auth.user != null && auth.user!.id != null) {
        context.read<ComplaintProvider>().fetchUserComplaints(auth.user!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = context.watch<ComplaintProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (auth.user != null && auth.user!.id != null) {
                context.read<ComplaintProvider>().fetchUserComplaints(auth.user!.id!);
              }
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: complaintProvider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : (complaintProvider.error != null && complaintProvider.complaints.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text('Sync Error: ${complaintProvider.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            final auth = context.read<AuthProvider>();
                            if (auth.user?.id != null) complaintProvider.fetchUserComplaints(auth.user!.id!);
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('RETRY SYNC'),
                        )
                      ],
                    ),
                  ),
                )
              : complaintProvider.complaints.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 64, color: Colors.blueGrey.shade200),
                          const SizedBox(height: 16),
                          Text('Your records list is empty.', style: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: complaintProvider.complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaintProvider.complaints[index];
                    return _ComplaintCard(complaint: complaint);
                  },
                ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  const _ComplaintCard({required this.complaint});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green;
      case 'in_progress': return Colors.orange;
      case 'pending': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isResolved = complaint.status.toLowerCase() == 'resolved';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        tilePadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: (complaint.status == 'resolved' ? Colors.green : Colors.blue).withOpacity(0.1),
          child: Icon(
            complaint.status == 'resolved' ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            color: complaint.status == 'resolved' ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(complaint.categoryName, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('•', style: TextStyle(color: Colors.grey))),
              _StatusBadge(status: complaint.status),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Text(complaint.description, style: const TextStyle(height: 1.5, fontSize: 14)),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text('OFFICIAL UPDATES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey, letterSpacing: 1.0)),
                const SizedBox(height: 12),
                if (complaint.responses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: Colors.blueGrey.shade400),
                        const SizedBox(width: 8),
                        Text('Awaiting administrative response...', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  )
                else
                  ...complaint.responses.map((resp) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded, size: 14, color: Color(0xFF6366F1)),
                            const SizedBox(width: 6),
                            Text(resp.adminUsername.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF6366F1))),
                            const Spacer(),
                            Text(resp.createdAt.split('T').first, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(resp.text, style: const TextStyle(fontSize: 14, height: 1.4)),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color _getBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green.shade100;
      case 'in_progress': return Colors.orange.shade100;
      case 'pending': return Colors.blue.shade100;
      default: return Colors.grey.shade100;
    }
  }

  Color _getTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return Colors.green.shade800;
      case 'in_progress': return Colors.orange.shade800;
      case 'pending': return Colors.blue.shade800;
      default: return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBadgeColor(status),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getTextColor(status),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}