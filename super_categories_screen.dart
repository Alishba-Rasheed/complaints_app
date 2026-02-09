import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../services/api_service.dart';

class SuperCategoriesScreen extends StatefulWidget {
  const SuperCategoriesScreen({super.key});

  @override
  State<SuperCategoriesScreen> createState() => _SuperCategoriesScreenState();
}

class _SuperCategoriesScreenState extends State<SuperCategoriesScreen> {
  final _nameController = TextEditingController();

  void _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final provider = context.read<ComplaintProvider>();
    final result = await provider.addCategory(name);

    if (mounted) {
      if (result != null) {
        Navigator.pop(context);
        _nameController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to add category'), 
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ComplaintProvider>().categories;

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return ListTile(
            tileColor: Colors.grey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ID: ${cat.id} | ${cat.createdAt?.split('T')[0] ?? ""}'),
            leading: const Icon(Icons.folder_open, color: Color(0xFF1976D2)),
          );
        },
      ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: () => _showAddDialog(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Category Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          Consumer<ComplaintProvider>(
            builder: (context, provider, _) => ElevatedButton(
              onPressed: provider.isLoading ? null : _addCategory, 
              child: provider.isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('ADD'),
            ),
          ),
        ],
      ),
    );
  }
}