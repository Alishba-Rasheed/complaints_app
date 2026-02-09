import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/announcement_models.dart';

/// Service for handling announcements and applications via Firebase Firestore
class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _announcementsRef => _firestore.collection('announcements');

  // ==================== ANNOUNCEMENTS ====================

  /// Get all active announcements (for users)
  /// Note: Fetches all and filters client-side to avoid requiring a composite index
  Stream<List<Announcement>> getActiveAnnouncements() {
    return _announcementsRef
        .snapshots()
        .map((snapshot) {
          debugPrint('Announcements snapshot received: ${snapshot.docs.length} docs');
          final announcements = snapshot.docs
              .map((doc) {
                debugPrint('Doc ${doc.id}: is_active=${(doc.data() as Map<String, dynamic>)['is_active']}');
                return Announcement.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              })
              .where((a) => a.isActive) // Filter active announcements client-side
              .toList();
          debugPrint('Active announcements count: ${announcements.length}');
          // Sort by created_at descending
          announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return announcements;
        })
        .handleError((error) {
          debugPrint('Error in announcement stream: $error');
          return <Announcement>[];
        });
  }

  /// Get all announcements (for super admin)
  Stream<List<Announcement>> getAllAnnouncements() {
    return _announcementsRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Get single announcement
  Future<Announcement?> getAnnouncement(String id) async {
    if (id.isEmpty) {
      debugPrint('Warning: getAnnouncement called with empty id');
      return null;
    }
    try {
      final doc = await _announcementsRef.doc(id).get();
      if (!doc.exists) return null;
      return Announcement.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      debugPrint('Error getting announcement: $e');
      return null;
    }
  }

  /// Create new announcement (super admin only)
  Future<String?> createAnnouncement(Announcement announcement) async {
    try {
      final docRef = await _announcementsRef.add(announcement.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating announcement: $e');
      rethrow;
    }
  }

  /// Update announcement
  Future<void> updateAnnouncement(String id, Map<String, dynamic> updates) async {
    if (id.isEmpty) {
      debugPrint('Warning: updateAnnouncement called with empty id');
      return;
    }
    try {
      await _announcementsRef.doc(id).update(updates);
    } catch (e) {
      debugPrint('Error updating announcement: $e');
      rethrow;
    }
  }

  /// Delete announcement
  Future<void> deleteAnnouncement(String id) async {
    if (id.isEmpty) {
      debugPrint('Warning: deleteAnnouncement called with empty id');
      return;
    }
    try {
      // Delete all applications first
      final apps = await _announcementsRef.doc(id).collection('applications').get();
      for (var doc in apps.docs) {
        await doc.reference.delete();
      }
      await _announcementsRef.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      rethrow;
    }
  }

  /// Toggle announcement active status
  Future<void> toggleAnnouncementStatus(String id, bool isActive) async {
    await updateAnnouncement(id, {'is_active': isActive});
  }

  // ==================== APPLICATIONS ====================

  /// Apply to an announcement
  Future<String?> applyToAnnouncement({
    required String announcementId,
    required String announcementTitle,
    required String userId,
    required String userName,
    required String userEmail,
    String? notes,
  }) async {
    if (announcementId.isEmpty || userId.isEmpty) {
      debugPrint('Warning: applyToAnnouncement called with empty ID(s)');
      return null;
    }
    try {
      // Check if already applied
      final existing = await _announcementsRef
          .doc(announcementId)
          .collection('applications')
          .where('user_id', isEqualTo: userId)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('You have already applied to this announcement');
      }

      final application = AnnouncementApplication(
        id: '',
        announcementId: announcementId,
        announcementTitle: announcementTitle,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        status: ApplicationStatus.pending,
        appliedAt: DateTime.now(),
        notes: notes,
      );

      final docRef = await _announcementsRef
          .doc(announcementId)
          .collection('applications')
          .add(application.toMap());

      // Increment application count
      await _announcementsRef.doc(announcementId).update({
        'application_count': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error applying: $e');
      rethrow;
    }
  }

  /// Check if user already applied
  Future<AnnouncementApplication?> getUserApplication(String announcementId, String userId) async {
    if (announcementId.isEmpty || userId.isEmpty) return null;
    try {
      final snapshot = await _announcementsRef
          .doc(announcementId)
          .collection('applications')
          .where('user_id', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return AnnouncementApplication.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      debugPrint('Error checking application: $e');
      return null;
    }
  }

  /// Get applications for an announcement (admin/super admin)
  Stream<List<AnnouncementApplication>> getApplications(String announcementId) {
    if (announcementId.isEmpty) return Stream.value([]);
    return _announcementsRef
        .doc(announcementId)
        .collection('applications')
        .orderBy('applied_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementApplication.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get all applications across all announcements (super admin)
  Stream<List<AnnouncementApplication>> getAllApplications() {
    return _firestore
        .collectionGroup('applications')
        .orderBy('applied_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementApplication.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get user's applications
  Stream<List<AnnouncementApplication>> getUserApplications(String userId) {
    return _firestore
        .collectionGroup('applications')
        .where('user_id', isEqualTo: userId)
        .orderBy('applied_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementApplication.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Update application status (approve/reject)
  Future<void> updateApplicationStatus({
    required String announcementId,
    required String applicationId,
    required ApplicationStatus status,
    String? responseNotes,
  }) async {
    if (announcementId.isEmpty || applicationId.isEmpty) {
      debugPrint('Warning: updateApplicationStatus called with empty ID(s)');
      return;
    }
    try {
      await _announcementsRef
          .doc(announcementId)
          .collection('applications')
          .doc(applicationId)
          .update({
        'status': status.name,
        'response_notes': responseNotes,
        'responded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating application status: $e');
      rethrow;
    }
  }
}