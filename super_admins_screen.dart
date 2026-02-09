import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../services/api_service.dart';
import '../../models/app_models.dart';
import 'super_user_management_screen.dart';

class SuperAdminsScreen extends StatefulWidget {
  const SuperAdminsScreen({super.key});

  @override
  State<SuperAdminsScreen> createState() => _SuperAdminsScreenState();
}

class _SuperAdminsScreenState extends State<SuperAdminsScreen> {
  List<dynamic> _admins = [];
  bool _isLoading = false;

  final _userController = TextEditingController();
  final _passController = TextEditingController();
  int? _selectedCatId;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/super/admins');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        debugPrint("Super Admins Raw Data: $data");
        
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          final possibleKeys = ['admins', 'data', 'users', 'results'];
          for (var key in possibleKeys) {
             if (data.containsKey(key) && data[key] is List) {
               list = data[key] as List;
               break;
             }
          }
        }
        setState(() {
          _admins = list.map((item) => User.fromJson(item)).toList();
        });
      }
    } catch (e) {
      debugPrint("Fetch Admins Error: $e");
    }
    setState(() => _isLoading = false);
  }

  void _addAdmin() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty || _selectedCatId == null) return;
    try {
      final response = await ApiService().post('/super/admins', data: {
        'username': _userController.text,
        'password': _passController.text,
        'category_id': _selectedCatId,
      });
      if (response.statusCode == 201 || response.statusCode == 200 && mounted) {
        _fetchAdmins();
        Navigator.pop(context);
        _userController.clear();
        _passController.clear();
      }
    } catch (e) {
       debugPrint("Add Admin Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ComplaintProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sub-Admins'),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_rounded),
            tooltip: 'Manage Participants',
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const SuperUserManagementScreen())
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _admins.length,
            itemBuilder: (context, index) {
              final User admin = _admins[index];
              final catName = categories.any((c) => c.id == admin.categoryId)
                  ? categories.firstWhere((c) => c.id == admin.categoryId).name
                  : 'Assigned ID: ${admin.categoryId ?? "Unknown"}';

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.shield)),
                  title: Text(admin.username),
                  subtitle: Text('Category: $catName'),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Add Sub-Admin'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _userController, decoration: const InputDecoration(hintText: 'Username')),
                  const SizedBox(height: 10),
                  TextField(controller: _passController, decoration: const InputDecoration(hintText: 'Password'), obscureText: true),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _selectedCatId = val),
                    hint: const Text('Select Category'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(onPressed: _addAdmin, child: const Text('ADD')),
            ],
          ),
        ),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}