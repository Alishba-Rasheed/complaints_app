import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/media_service.dart';

class SubmitComplaintScreen extends StatefulWidget {
  final int? initialCategoryId;
  const SubmitComplaintScreen({super.key, this.initialCategoryId});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _newCategoryController = TextEditingController();
  int? _selectedCategoryId;
  bool _isSubmitting = false;
  bool _isAddingNewCategory = false;
  
  // Media attachments
  final MediaService _mediaService = MediaService();
  final List<MediaFile> _attachedMedia = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    
    // Fetch categories if they haven't been loaded yet
    final provider = context.read<ComplaintProvider>();
    if (provider.categories.isEmpty) {
      Future.microtask(() => provider.fetchCategories());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  /// Show media picker options
  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Add Attachment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMediaOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildMediaOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildMediaOption(
                  icon: Icons.videocam,
                  label: 'Record Video',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo(ImageSource.camera);
                  },
                ),
                _buildMediaOption(
                  icon: Icons.video_library,
                  label: 'Video Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Pick image from source
  Future<void> _pickImage(ImageSource source) async {
    if (_attachedMedia.length >= MediaService.maxMediaCount) {
      _showMaxMediaWarning();
      return;
    }
    
    try {
      final media = await _mediaService.pickImage(source: source);
      if (media != null && mounted) {
        setState(() => _attachedMedia.add(media));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Pick video from source
  Future<void> _pickVideo(ImageSource source) async {
    if (_attachedMedia.length >= MediaService.maxMediaCount) {
      _showMaxMediaWarning();
      return;
    }
    
    try {
      final media = await _mediaService.pickVideo(source: source);
      if (media != null && mounted) {
        setState(() => _attachedMedia.add(media));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showMaxMediaWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maximum ${MediaService.maxMediaCount} attachments allowed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Remove attached media
  void _removeMedia(int index) {
    setState(() {
      final media = _attachedMedia.removeAt(index);
      _mediaService.deleteLocalMedia(media.path);
    });
  }

  /// Build media preview widget
  Widget _buildMediaPreview(MediaFile media, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: media.isImage
              ? Image.file(File(media.path), fit: BoxFit.cover)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    if (media.thumbnailPath != null)
                      Image.file(File(media.thumbnailPath!), fit: BoxFit.cover)
                    else
                      Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.videocam, color: Colors.white, size: 40),
                      ),
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(Icons.play_circle_outline, color: Colors.white, size: 35),
                      ),
                    ),
                  ],
                ),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 14,
          child: GestureDetector(
            onTap: () => _removeMedia(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        // File size indicator
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              media.sizeFormatted,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
        // Video indicator
        if (media.isVideo)
          Positioned(
            bottom: 4,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VIDEO',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  void _submit() async {
    final complaintProvider = context.read<ComplaintProvider>();
    final userId = context.read<AuthProvider>().user?.id ?? 1;

    int? categoryId = _selectedCategoryId;

    // Handle new category creation
    if (_isAddingNewCategory) {
      if (_newCategoryController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter category name')));
        return;
      }
      
      setState(() => _isSubmitting = true);
      final newCat = await complaintProvider.addCategory(_newCategoryController.text);
      if (newCat == null) {
        if (mounted) setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create category')));
        return;
      }
      categoryId = newCat.id;
    }

    if (categoryId == null || _titleController.text.isEmpty || _descController.text.isEmpty) {
      if (mounted) setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (!_isSubmitting) setState(() => _isSubmitting = true);
    
    // Submit complaint with media paths
    final mediaUrls = _attachedMedia.map((m) => m.path).toList();
    final mediaTypes = _attachedMedia.map((m) => m.isImage ? 'image' : 'video').toList();
    
    final success = await complaintProvider.submitComplaint(
      categoryId,
      _titleController.text,
      _descController.text,
      userId,
      mediaUrls: mediaUrls,
      mediaTypes: mediaTypes,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        final categoryName = _isAddingNewCategory 
            ? _newCategoryController.text 
            : complaintProvider.categories.firstWhere((c) => c.id == categoryId).name;
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully submitted to $categoryName!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(complaintProvider.error ?? 'Failed to submit. Please try again.'),
            backgroundColor: Colors.redAccent,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Complaint', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Consumer<ComplaintProvider>(
              builder: (context, provider, _) {
                final categories = provider.categories;
                final isLoading = provider.isLoading;
                final error = provider.error;

                if (error != null && categories.isEmpty) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Expanded(child: Text("Categories failed to load: $error", style: const TextStyle(color: Colors.redAccent))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => provider.fetchCategories(),
                        icon: const Icon(Icons.refresh), 
                        label: const Text('RETRY FETCHING'),
                      ),
                    ],
                  );
                }
                
                return DropdownButtonFormField<int>(
                  value: _isAddingNewCategory ? -1 : _selectedCategoryId,
                  hint: Text(isLoading ? 'Loading categories...' : 'Select Category'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category', 
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    ...categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))),
                    const DropdownMenuItem(value: -1, child: Row(
                      children: [
                        Icon(Icons.add, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Add New Category...', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    )),
                  ],
                  onChanged: isLoading ? null : (val) {
                    setState(() {
                      if (val == -1) {
                        _isAddingNewCategory = true;
                        _selectedCategoryId = null;
                      } else {
                        _isAddingNewCategory = false;
                        _selectedCategoryId = val;
                      }
                    });
                  },
                  validator: (val) => (val == null && !_isAddingNewCategory) ? 'Please select a category' : null,
                );
              },
            ),
            if (_isAddingNewCategory) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _newCategoryController,
                decoration: const InputDecoration(
                  labelText: 'New Category Name', 
                  prefixIcon: Icon(Icons.add_circle_outline),
                  hintText: 'Enter new category (e.g. Park)',
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true, prefixIcon: Padding(padding: EdgeInsets.only(bottom: 80), child: Icon(Icons.description_outlined))),
            ),
            
            // Media Attachments Section
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attachments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_attachedMedia.length}/${MediaService.maxMediaCount}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Media preview list
            if (_attachedMedia.isNotEmpty) ...[
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachedMedia.length,
                  itemBuilder: (context, index) => _buildMediaPreview(_attachedMedia[index], index),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Add media button
            if (_attachedMedia.length < MediaService.maxMediaCount)
              OutlinedButton.icon(
                onPressed: _showMediaPickerOptions,
                icon: const Icon(Icons.attach_file),
                label: Text(_attachedMedia.isEmpty ? 'Add Photo/Video' : 'Add More'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SUBMIT COMPLAINT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}