import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/system_provider.dart';
import '../../models/app_models.dart';

class SuperSettingsScreen extends StatefulWidget {
  const SuperSettingsScreen({super.key});

  @override
  State<SuperSettingsScreen> createState() => _SuperSettingsScreenState();
}

class _SuperSettingsScreenState extends State<SuperSettingsScreen> {
  final _phoneController = TextEditingController();
  final _faqController = TextEditingController();
  final _helpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SystemProvider>().settings;
    _phoneController.text = settings.supportNumber;
    _faqController.text = settings.faqUrl;
    _helpController.text = settings.helpText;
  }

  void _save() async {
    final provider = context.read<SystemProvider>();
    final newSettings = SystemSettings(
      supportNumber: _phoneController.text,
      faqUrl: _faqController.text,
      helpText: _helpController.text,
    );
    
    final success = await provider.updateSettings(newSettings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Settings updated successfully' : 'Update failed'),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Support Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('These details are visible to all users on their home page.', style: TextStyle(color: Colors.blueGrey.shade400)),
            const SizedBox(height: 32),
            _buildField('Support Number', Icons.phone_rounded, _phoneController),
            const SizedBox(height: 20),
            _buildField('FAQ / Help URL', Icons.help_rounded, _faqController),
            const SizedBox(height: 20),
            _buildField('Help Message', Icons.message_rounded, _helpController, maxLines: 3),
            const SizedBox(height: 48),
            Consumer<SystemProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SAVE GLOBAL SETTINGS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

  Widget _buildField(String label, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}