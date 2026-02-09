import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../models/app_models.dart';
import 'respond_screen.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ComplaintProvider>().fetchAdminComplaints());
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = context.watch<ComplaintProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Category Complaints')),
      body: complaintProvider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => complaintProvider.fetchAdminComplaints(),
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: complaintProvider.complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaintProvider.complaints[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: (complaint.status == 'resolved' ? Colors.green : Colors.blue).withOpacity(0.1),
                        child: Icon(
                          complaint.status == 'resolved' ? Icons.check_rounded : Icons.priority_high_rounded,
                          color: complaint.status == 'resolved' ? Colors.green : Colors.blue,
                        ),
                      ),
                      title: Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submitted by: ${complaint.userUsername ?? "User #" + (complaint.userId?.toString() ?? "??")}',
                              style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            _StatusBadge(status: complaint.status),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => RespondScreen(complaint: complaint))
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved': color = Colors.green; break;
      case 'in_progress': color = Colors.orange; break;
       default: color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}