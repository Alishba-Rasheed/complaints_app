import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

/// Represents a media file attached to a complaint
class MediaFile {
  final String path;
  final MediaType type;
  final String? thumbnailPath;
  final int sizeBytes;
  final String fileName;

  MediaFile({
    required this.path,
    required this.type,
    this.thumbnailPath,
    required this.sizeBytes,
    required this.fileName,
  });

  bool get isImage => type == MediaType.image;
  bool get isVideo => type == MediaType.video;
  
  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum MediaType { image, video }

/// Service for handling media operations (picking, saving, uploading)
class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ImagePicker _picker = ImagePicker();
  
  // File size limits
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoSizeBytes = 50 * 1024 * 1024; // 50 MB
  static const int maxMediaCount = 5;

  /// Pick an image from gallery or camera
  Future<MediaFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile == null) return null;
      
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      
      if (fileSize > maxImageSizeBytes) {
        throw Exception('Image too large (max ${maxImageSizeBytes ~/ (1024 * 1024)}MB)');
      }
      
      // Save to app storage
      final savedPath = await _saveToLocalStorage(file, MediaType.image);
      
      return MediaFile(
        path: savedPath,
        type: MediaType.image,
        sizeBytes: fileSize,
        fileName: pickedFile.name,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  /// Pick a video from gallery or camera
  Future<MediaFile?> pickVideo({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
      
      if (pickedFile == null) return null;
      
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      
      if (fileSize > maxVideoSizeBytes) {
        throw Exception('Video too large (max ${maxVideoSizeBytes ~/ (1024 * 1024)}MB)');
      }
      
      // Save to app storage
      final savedPath = await _saveToLocalStorage(file, MediaType.video);
      
      // Generate thumbnail
      final thumbnailPath = await _generateVideoThumbnail(savedPath);
      
      return MediaFile(
        path: savedPath,
        type: MediaType.video,
        thumbnailPath: thumbnailPath,
        sizeBytes: fileSize,
        fileName: pickedFile.name,
      );
    } catch (e) {
      debugPrint('Error picking video: $e');
      rethrow;
    }
  }

  /// Save file to local app storage
  Future<String> _saveToLocalStorage(File file, MediaType type) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/complaint_media');
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.path.split('.').last;
    final newFileName = '${type == MediaType.image ? 'img' : 'vid'}_$timestamp.$extension';
    final newPath = '${mediaDir.path}/$newFileName';
    
    await file.copy(newPath);
    return newPath;
  }

  /// Generate thumbnail for video
  Future<String?> _generateVideoThumbnail(String videoPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory('${appDir.path}/complaint_thumbnails');
      
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }
      
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );
      
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  /// Upload media files to server and return URLs
  Future<List<String>> uploadMedia(List<MediaFile> mediaFiles, int complaintId) async {
    final List<String> uploadedUrls = [];
    
    for (final media in mediaFiles) {
      try {
        final file = File(media.path);
        if (!await file.exists()) continue;
        
        final mimeType = lookupMimeType(media.path) ?? 'application/octet-stream';
        
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            media.path,
            filename: media.fileName,
            contentType: DioMediaType.parse(mimeType),
          ),
          'complaint_id': complaintId,
          'media_type': media.type == MediaType.image ? 'image' : 'video',
        });
        
        final response = await ApiService().dio.post(
          '/complaints/upload-media',
          data: formData,
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final url = response.data['url'] ?? response.data['file_url'];
          if (url != null) {
            uploadedUrls.add(url);
          }
        }
      } catch (e) {
        debugPrint('Error uploading media: $e');
      }
    }
    
    return uploadedUrls;
  }

  /// Get media type from file path
  MediaType? getMediaType(String path) {
    final mimeType = lookupMimeType(path);
    if (mimeType == null) return null;
    
    if (mimeType.startsWith('image/')) return MediaType.image;
    if (mimeType.startsWith('video/')) return MediaType.video;
    return null;
  }

  /// Delete local media file
  Future<void> deleteLocalMedia(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting media: $e');
    }
  }

  /// Clean up old media files (older than 30 days)
  Future<void> cleanupOldMedia() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/complaint_media');
      
      if (!await mediaDir.exists()) return;
      
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      await for (final entity in mediaDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(thirtyDaysAgo)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old media: $e');
    }
  }
}