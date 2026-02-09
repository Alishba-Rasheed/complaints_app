import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../admin/respond_screen.dart';

class SuperAllComplaintsScreen extends StatelessWidget {
  const SuperAllComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final complaintProvider = context.watch<ComplaintProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Global Activity', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                        const Icon(Icons.sync_problem_rounded, size: 60, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text('System Sync Issue: ${complaintProvider.error}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => complaintProvider.fetchAllComplaints(),
                          child: const Text('RETRY FULL SYNC'),
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
                          Icon(Icons.feed_rounded, size: 64, color: Colors.blueGrey.shade100),
                          const SizedBox(height: 16),
                          Text('No global activity found.', style: TextStyle(color: Colors.blueGrey.shade400)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: complaintProvider.complaints.length,
                      itemBuilder: (context, index) {
                        final complaint = complaintProvider.complaints[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blueGrey.shade50),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: (complaint.status == 'resolved' ? Colors.green : Colors.blue).withOpacity(0.1),
                              child: Icon(complaint.status == 'resolved' ? Icons.verified_rounded : Icons.pending_rounded, size: 20, color: complaint.status == 'resolved' ? Colors.green : Colors.blue),
                            ),
                            title: Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Text(complaint.userUsername?.toUpperCase() ?? "USER", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 10)),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('•', style: TextStyle(color: Colors.grey))),
                                  Text(complaint.categoryName, style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 11)),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RespondScreen(complaint: complaint)),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}