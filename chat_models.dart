/// Chat-related models for Firebase Firestore

class ChatParticipant {
  final String id;
  final String name;
  final String email;
  final String role; // 'user', 'admin', 'super_admin', 'suspended'
  final String? prevRole; // To restore after suspension
  final String? avatarUrl;
  final String? categoryId; // Associated category for admins
  final bool isOnline;
  final DateTime? lastSeen;

  ChatParticipant({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.prevRole,
    this.avatarUrl,
    this.categoryId,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      id: (map['id'] ?? map['userId'] ?? '').toString(),
      name: (map['name'] ?? map['username'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'user').toString(),
      prevRole: map['prev_role']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      categoryId: map['category_id']?.toString(),
      isOnline: map['is_online'] == true,
      lastSeen: map['last_seen'] != null 
          ? DateTime.tryParse(map['last_seen'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'prev_role': prevRole,
    'avatar_url': avatarUrl,
    'category_id': categoryId,
    'is_online': isOnline,
    'last_seen': lastSeen?.toIso8601String(),
  };

  String get roleDisplay {
    switch (role) {
      case 'super_admin': 
      case 'super admin':
      case 'super':
        return 'Super Admin';
      case 'admin': return 'Admin';
      default: return 'User';
    }
  }
}

enum ChatRequestStatus { pending, accepted, rejected }

class ChatRequest {
  final String id;
  final ChatParticipant sender;
  final ChatParticipant receiver;
  final ChatRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;

  ChatRequest({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  factory ChatRequest.fromMap(Map<String, dynamic> map, String docId) {
    return ChatRequest(
      id: docId,
      sender: ChatParticipant.fromMap(map['sender'] ?? {}),
      receiver: ChatParticipant.fromMap(map['receiver'] ?? {}),
      status: ChatRequestStatus.values.firstWhere(
        (s) => s.name == (map['status'] ?? 'pending'),
        orElse: () => ChatRequestStatus.pending,
      ),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      respondedAt: map['responded_at'] != null 
          ? DateTime.tryParse(map['responded_at'].toString())
          : null,
      message: map['message'],
    );
  }

  Map<String, dynamic> toMap() => {
    'sender': sender.toMap(),
    'receiver': receiver.toMap(),
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'responded_at': respondedAt?.toIso8601String(),
    'message': message,
  };

  bool get isPending => status == ChatRequestStatus.pending;
  bool get isAccepted => status == ChatRequestStatus.accepted;
}

class ChatRoom {
  final String id;
  final List<String> participantIds;
  final Map<String, ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, int> unreadCounts;

  ChatRoom({
    required this.id,
    required this.participantIds,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCounts = const {},
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String docId) {
    final participantsMap = <String, ChatParticipant>{};
    if (map['participants_data'] != null) {
      (map['participants_data'] as Map<String, dynamic>).forEach((key, value) {
        participantsMap[key] = ChatParticipant.fromMap(value);
      });
    }

    return ChatRoom(
      id: docId,
      participantIds: List<String>.from(map['participant_ids'] ?? []),
      participants: participantsMap,
      lastMessage: map['last_message'] != null 
          ? ChatMessage.fromMap(map['last_message'], '')
          : null,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
      unreadCounts: Map<String, int>.from(map['unread_counts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'participant_ids': participantIds,
    'participants_data': participants.map((k, v) => MapEntry(k, v.toMap())),
    'last_message': lastMessage?.toMap(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'unread_counts': unreadCounts,
  };

  ChatParticipant? getOtherParticipant(String currentUserId) {
    final otherId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participants[otherId];
  }

  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessage(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      senderId: map['sender_id'] ?? '',
      senderName: map['sender_name'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      isRead: map['is_read'] ?? false,
      type: MessageType.values.firstWhere(
        (t) => t.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'sender_id': senderId,
    'sender_name': senderName,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'is_read': isRead,
    'type': type.name,
  };

  bool isMine(String currentUserId) => senderId == currentUserId;
}

enum MessageType { text, image, video, file }