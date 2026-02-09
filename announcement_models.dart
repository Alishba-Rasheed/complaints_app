/// Models for Official Announcements System

enum AnnouncementType { event, scheme, notice, general }

class Announcement {
  final String id;
  final String title;
  final String description;
  final AnnouncementType type;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final DateTime createdAt;
  final DateTime? deadline;
  final String createdById;
  final String createdByName;
  final bool isActive;
  final bool allowApplications;
  final int applicationCount;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrls = const [],
    this.videoUrls = const [],
    required this.createdAt,
    this.deadline,
    required this.createdById,
    required this.createdByName,
    this.isActive = true,
    this.allowApplications = true,
    this.applicationCount = 0,
  });

  factory Announcement.fromMap(Map<String, dynamic> map, String docId) {
    return Announcement(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: AnnouncementType.values.firstWhere(
        (t) => t.name == (map['type'] ?? 'general'),
        orElse: () => AnnouncementType.general,
      ),
      imageUrls: List<String>.from(map['image_urls'] ?? []),
      videoUrls: List<String>.from(map['video_urls'] ?? []),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'].toString())
          : null,
      createdById: map['created_by_id'] ?? '',
      createdByName: map['created_by_name'] ?? '',
      isActive: map['is_active'] ?? true,
      allowApplications: map['allow_applications'] ?? true,
      applicationCount: map['application_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'type': type.name,
    'image_urls': imageUrls,
    'video_urls': videoUrls,
    'created_at': createdAt.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
    'created_by_id': createdById,
    'created_by_name': createdByName,
    'is_active': isActive,
    'allow_applications': allowApplications,
    'application_count': applicationCount,
  };

  bool get isExpired => deadline != null && deadline!.isBefore(DateTime.now());
  bool get canApply => isActive && allowApplications && !isExpired;

  String get typeLabel {
    switch (type) {
      case AnnouncementType.event: return 'Event';
      case AnnouncementType.scheme: return 'Scheme';
      case AnnouncementType.notice: return 'Notice';
      case AnnouncementType.general: return 'Announcement';
    }
  }

  String get typeEmoji {
    switch (type) {
      case AnnouncementType.event: return '🎉';
      case AnnouncementType.scheme: return '📋';
      case AnnouncementType.notice: return '📢';
      case AnnouncementType.general: return '📌';
    }
  }
}

enum ApplicationStatus { pending, approved, rejected }

class AnnouncementApplication {
  final String id;
  final String announcementId;
  final String announcementTitle;
  final String userId;
  final String userName;
  final String userEmail;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final String? notes;
  final String? responseNotes;
  final DateTime? respondedAt;

  AnnouncementApplication({
    required this.id,
    required this.announcementId,
    required this.announcementTitle,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.appliedAt,
    this.notes,
    this.responseNotes,
    this.respondedAt,
  });

  factory AnnouncementApplication.fromMap(Map<String, dynamic> map, String docId) {
    return AnnouncementApplication(
      id: docId,
      announcementId: map['announcement_id'] ?? '',
      announcementTitle: map['announcement_title'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      userEmail: map['user_email'] ?? '',
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == (map['status'] ?? 'pending'),
        orElse: () => ApplicationStatus.pending,
      ),
      appliedAt: map['applied_at'] != null
          ? DateTime.parse(map['applied_at'].toString())
          : DateTime.now(),
      notes: map['notes'],
      responseNotes: map['response_notes'],
      respondedAt: map['responded_at'] != null
          ? DateTime.tryParse(map['responded_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'announcement_id': announcementId,
    'announcement_title': announcementTitle,
    'user_id': userId,
    'user_name': userName,
    'user_email': userEmail,
    'status': status.name,
    'applied_at': appliedAt.toIso8601String(),
    'notes': notes,
    'response_notes': responseNotes,
    'responded_at': respondedAt?.toIso8601String(),
  };

  bool get isPending => status == ApplicationStatus.pending;
  bool get isApproved => status == ApplicationStatus.approved;
}