import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/announcement_models.dart';
import '../../services/announcement_service.dart';
import '../../providers/auth_provider.dart';

/// Super Admin screen to create new announcements
class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AnnouncementService _service = AnnouncementService();

  AnnouncementType _selectedType = AnnouncementType.general;
  bool _allowApplications = true;
  DateTime? _deadline;
  List<String> _imageUrls = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
        actions: [
          TextButton.icon(
            onPressed: _isSubmitting ? null : _submitAnnouncement,
            icon: _isSubmitting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.publish),
            label: const Text('Publish'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              Text('Announcement Type', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 12),
              _buildTypeSelector(theme),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter announcement title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide detailed information about this announcement...',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
              ),
              const SizedBox(height: 24),

              // Settings row
              Row(
                children: [
                  Expanded(
                    child: _buildSettingCard(
                      theme,
                      icon: Icons.how_to_reg,
                      title: 'Allow Applications',
                      child: Switch(
                        value: _allowApplications,
                        onChanged: (v) => setState(() => _allowApplications = v),
                        activeColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSettingCard(
                      theme,
                      icon: Icons.event,
                      title: 'Deadline',
                      child: TextButton(
                        onPressed: _selectDeadline,
                        child: Text(
                          _deadline != null 
                              ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                              : 'Set Date',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Images section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Images (URLs)', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                  IconButton(
                    onPressed: _addImageUrl,
                    icon: Icon(Icons.add_photo_alternate, color: theme.colorScheme.primary),
                  ),
                ],
              ),
              if (_imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _imageUrls.asMap().entries.map((entry) {
                    return Chip(
                      label: Text('Image ${entry.key + 1}', style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _imageUrls.removeAt(entry.key)),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 32),

              // Preview
              _buildPreviewCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AnnouncementType.values.map((type) {
        final isSelected = _selectedType == type;
        final colors = _getTypeColors(type);
        
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? LinearGradient(colors: colors) : null,
              color: isSelected ? null : colors[0].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.transparent : colors[0].withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getTypeEmoji(type), style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  _getTypeLabel(type),
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors[0],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingCard(ThemeData theme, {required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final colors = _getTypeColors(_selectedType);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors[0].withValues(alpha: 0.1), colors[1].withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors[0].withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: colors[0]),
              const SizedBox(width: 8),
              Text('Preview', style: TextStyle(fontWeight: FontWeight.bold, color: colors[0])),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_getTypeEmoji(_selectedType)} ${_getTypeLabel(_selectedType)}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _titleController.text.isEmpty ? 'Your Title Here' : _titleController.text,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            _descriptionController.text.isEmpty ? 'Your description will appear here...' : _descriptionController.text,
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _addImageUrl() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Image URL'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'https://example.com/image.jpg',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() => _imageUrls.add(controller.text));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>();
      final announcement = Announcement(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        imageUrls: _imageUrls,
        createdAt: DateTime.now(),
        deadline: _deadline,
        createdById: auth.user?.id.toString() ?? '',
        createdByName: auth.user?.username ?? 'Super Admin',
        allowApplications: _allowApplications,
      );

      await _service.createAnnouncement(announcement);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement published!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<Color> _getTypeColors(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.event: return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
      case AnnouncementType.scheme: return [const Color(0xFF10B981), const Color(0xFF34D399)];
      case AnnouncementType.notice: return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case AnnouncementType.general: return [const Color(0xFF6366F1), const Color(0xFF818CF8)];
    }
  }

  String _getTypeEmoji(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.event: return '🎉';
      case AnnouncementType.scheme: return '📋';
      case AnnouncementType.notice: return '📢';
      case AnnouncementType.general: return '📌';
    }
  }

  String _getTypeLabel(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.event: return 'Event';
      case AnnouncementType.scheme: return 'Scheme';
      case AnnouncementType.notice: return 'Notice';
      case AnnouncementType.general: return 'General';
    }
  }
}