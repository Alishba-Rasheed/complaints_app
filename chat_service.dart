import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_models.dart';

/// Service for handling all chat-related Firebase Firestore operations
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _chatRequestsRef => _firestore.collection('chat_requests');
  CollectionReference get _chatRoomsRef => _firestore.collection('chat_rooms');
  CollectionReference get _systemRef => _firestore.collection('system');
  CollectionReference get _categoriesRef => _firestore.collection('categories');

  // ==================== USER MANAGEMENT ====================

  /// Get all admins
  Stream<List<ChatParticipant>> getAdmins() {
    debugPrint('Getting admins from Firebase');
    return _usersRef
        .where('role', whereIn: ['admin', 'super_admin', 'suspended'])
        .snapshots()
        .map((snapshot) {
          debugPrint('Admins snapshot: ${snapshot.docs.length} docs');
          return snapshot.docs
              .map((doc) => ChatParticipant.fromMap(doc.data() as Map<String, dynamic>))
              .where((p) => p.role == 'admin' || p.role == 'super_admin' || (p.role == 'suspended' && (p.prevRole == 'admin' || p.prevRole == 'super_admin')))
              .toList();
        })
        .handleError((error) {
          debugPrint('Error in getAdmins stream: $error');
          return <ChatParticipant>[];
        });
  }

  /// Get single user data
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  /// Get all super admins
  Stream<List<ChatParticipant>> getSuperAdmins() {
    debugPrint('Getting super admins from Firebase');
    return _usersRef
        .where('role', isEqualTo: 'super_admin')
        .snapshots()
        .map((snapshot) {
          debugPrint('Super admins snapshot: ${snapshot.docs.length} docs');
          return snapshot.docs
              .map((doc) => ChatParticipant.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        })
        .handleError((error) {
          debugPrint('Error in getSuperAdmins stream: $error');
          return <ChatParticipant>[];
        });
  }

  /// Get all users (for admin/super admin view)
  Stream<List<ChatParticipant>> getUsers() {
    debugPrint('Getting users from Firebase');
    return _usersRef
        .where('role', whereIn: ['user', 'suspended'])
        .snapshots()
        .map((snapshot) {
          debugPrint('Users snapshot: ${snapshot.docs.length} docs');
          return snapshot.docs
              .map((doc) => ChatParticipant.fromMap(doc.data() as Map<String, dynamic>))
              .where((p) => p.role == 'user' || (p.role == 'suspended' && (p.prevRole == 'user' || p.prevRole == null)))
              .toList();
        })
        .handleError((error) {
          debugPrint('Error in getUsers stream: $error');
          return <ChatParticipant>[];
        });
  }

  /// Listen to single user data for real-time role/status sync
  Stream<Map<String, dynamic>?> watchUser(String userId) {
    if (userId.isEmpty || userId == '0') return Stream.value(null);
    return _usersRef.doc(userId).snapshots().map((doc) => 
      doc.exists ? doc.data() as Map<String, dynamic> : null
    );
  }

  /// Register/Update user in Firestore
  Future<void> registerUser(ChatParticipant user) async {
    // Validate user ID to prevent Firebase "document path must be non-empty" error
    if (user.id.isEmpty) {
      debugPrint('Warning: Cannot register user with empty ID');
      return;
    }
    
    try {
      await _usersRef.doc(user.id).set(user.toMap(), SetOptions(merge: true));
      debugPrint('Successfully registered user: ${user.id} (${user.name})');
    } catch (e) {
      debugPrint('Error registering user: $e');
      rethrow;
    }
  }

  /// Update user online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    // Validate user ID to prevent Firebase errors
    if (userId.isEmpty) {
      debugPrint('Warning: Cannot update online status for empty userId');
      return;
    }
    
    try {
      await _usersRef.doc(userId).update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  // ==================== CHAT REQUESTS ====================

  /// Send a chat request to admin/super admin
  Future<String?> sendChatRequest({
    required ChatParticipant sender,
    required ChatParticipant receiver,
    String? message,
  }) async {
    try {
      // Check if request already exists
      final existing = await _chatRequestsRef
          .where('sender.id', isEqualTo: sender.id)
          .where('receiver.id', isEqualTo: receiver.id)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id; // Return existing request ID
      }

      // Check if chat room already exists
      final existingRoom = await _chatRoomsRef
          .where('participant_ids', arrayContains: sender.id)
          .get();

      for (var doc in existingRoom.docs) {
        final room = ChatRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (room.participantIds.contains(receiver.id)) {
          return null; // Chat already exists
        }
      }

      final request = ChatRequest(
        id: '',
        sender: sender,
        receiver: receiver,
        status: ChatRequestStatus.pending,
        createdAt: DateTime.now(),
        message: message,
      );

      final docRef = await _chatRequestsRef.add(request.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error sending chat request: $e');
      rethrow;
    }
  }

  /// Get pending requests for a user (as receiver)
  /// Note: Fetches all pending requests and filters client-side to avoid composite index requirement
  Stream<List<ChatRequest>> getPendingRequests(String userId) {
    return _chatRequestsRef
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ChatRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .where((request) => request.receiver.id == userId) 
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        })
        .handleError((error) {
          debugPrint('Error in getPendingRequests stream: $error');
          return <ChatRequest>[];
        });
  }

  /// Get sent requests by a user
  Stream<List<ChatRequest>> getSentRequests(String userId) {
    return _chatRequestsRef
        .where('sender.id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Accept a chat request and create chat room
  Future<String?> acceptChatRequest(String requestId) async {
    if (requestId.isEmpty) {
      debugPrint('Warning: acceptChatRequest called with empty requestId');
      return null;
    }
    try {
      final requestDoc = await _chatRequestsRef.doc(requestId).get();
      if (!requestDoc.exists) return null;

      final request = ChatRequest.fromMap(
        requestDoc.data() as Map<String, dynamic>,
        requestId,
      );

      // Update request status
      await _chatRequestsRef.doc(requestId).update({
        'status': 'accepted',
        'responded_at': DateTime.now().toIso8601String(),
      });

      // Create chat room
      final room = ChatRoom(
        id: '',
        participantIds: [request.sender.id, request.receiver.id],
        participants: {
          request.sender.id: request.sender,
          request.receiver.id: request.receiver,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final roomRef = await _chatRoomsRef.add(room.toMap());
      final roomId = roomRef.id;

      // Update request with the room ID for easier lookup
      await _chatRequestsRef.doc(requestId).update({
        'room_id': roomId,
      });

      return roomId;
    } catch (e) {
      debugPrint('Error accepting chat request: $e');
      rethrow;
    }
  }

  /// Reject a chat request
  Future<void> rejectChatRequest(String requestId) async {
    if (requestId.isEmpty) {
      debugPrint('Warning: rejectChatRequest called with empty requestId');
      return;
    }
    try {
      await _chatRequestsRef.doc(requestId).update({
        'status': 'rejected',
        'responded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error rejecting chat request: $e');
      rethrow;
    }
  }

  // ==================== CHAT ROOMS ====================

  /// Get all chat rooms for a user
  /// Note: Fetches and sorts client-side to avoid composite index requirement
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    debugPrint('Getting chat rooms for user: $userId');
    
    // Validate userId to prevent Firebase "invalid argument" errors
    if (userId.isEmpty) {
      debugPrint('Warning: Empty userId provided to getChatRooms');
      return Stream.value([]);
    }
    
    return _chatRoomsRef
        .where('participant_ids', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          debugPrint('Chat rooms snapshot: ${snapshot.docs.length} docs');
          final rooms = snapshot.docs
              .map((doc) => ChatRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          // Sort by updated_at descending (client-side)
          rooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return rooms;
        })
        .handleError((error) {
          debugPrint('Error in getChatRooms stream: $error');
          return <ChatRoom>[];
        });
  }

  /// Get a specific chat room
  Stream<ChatRoom?> getChatRoom(String roomId) {
    if (roomId.isEmpty) {
      debugPrint('Warning: getChatRoom called with empty roomId');
      return Stream.value(null);
    }
    return _chatRoomsRef.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Find room ID between two users
  Future<String?> getChatRoomIdBetweenUsers(String userId1, String userId2) async {
    if (userId1.isEmpty || userId2.isEmpty) return null;
    
    try {
      // First check chat_requests for an accepted request with room_id
      final requests = await _chatRequestsRef
          .where('status', isEqualTo: 'accepted')
          .get();
      
      for (var doc in requests.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['sender']?['id'] as String?;
        final receiverId = data['receiver']?['id'] as String?;
        final roomId = data['room_id'] as String?;
        
        if (roomId != null && 
            ((senderId == userId1 && receiverId == userId2) || 
             (senderId == userId2 && receiverId == userId1))) {
          return roomId;
        }
      }

      // Fallback: Check chat_rooms collection directly
      final rooms = await _chatRoomsRef
          .where('participant_ids', arrayContains: userId1)
          .get();
      
      for (var doc in rooms.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(data['participant_ids'] ?? []);
        if (participantIds.contains(userId2)) {
          return doc.id;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting room ID: $e');
      return null;
    }
  }

  // ==================== MESSAGES ====================

  /// Send a message to a chat room
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    if (roomId.isEmpty || senderId.isEmpty) {
      debugPrint('Warning: sendMessage called with empty ID(s)');
      return;
    }
    try {
      final message = ChatMessage(
        id: '',
        senderId: senderId,
        senderName: senderName,
        content: content,
        timestamp: DateTime.now(),
        type: type,
      );

      // Add message to subcollection
      await _chatRoomsRef
          .doc(roomId)
          .collection('messages')
          .add(message.toMap());

      // Update chat room with last message
      await _chatRoomsRef.doc(roomId).update({
        'last_message': message.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Increment unread count for other participant
      final roomDoc = await _chatRoomsRef.doc(roomId).get();
      final room = ChatRoom.fromMap(roomDoc.data() as Map<String, dynamic>, roomId);
      final otherUserId = room.participantIds.firstWhere((id) => id != senderId, orElse: () => '');
      
      if (otherUserId.isNotEmpty) {
        await _chatRoomsRef.doc(roomId).update({
          'unread_counts.$otherUserId': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Get messages stream for a chat room
  Stream<List<ChatMessage>> getMessages(String roomId) {
    if (roomId.isEmpty) {
      debugPrint('Warning: getMessages called with empty roomId');
      return Stream.value([]);
    }
    return _chatRoomsRef
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String roomId, String userId) async {
    if (roomId.isEmpty || userId.isEmpty) {
      debugPrint('Warning: markMessagesAsRead called with empty ID(s)');
      return;
    }
    try {
      // Reset unread count
      await _chatRoomsRef.doc(roomId).update({
        'unread_counts.$userId': 0,
      });

      // Mark individual messages as read (optional, for detailed tracking)
      final unreadMessages = await _chatRoomsRef
          .doc(roomId)
          .collection('messages')
          .where('sender_id', isNotEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'is_read': true});
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Get total unread count for a user
  Stream<int> getTotalUnreadCount(String userId) {
    return _chatRoomsRef
        .where('participant_ids', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final room = ChatRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            total += room.getUnreadCount(userId);
          }
          return total;
        });
  }

  // ==================== SYSTEM & CATEGORIES SYNC ====================

  /// Update global categories in Firestore for cross-device sync
  Future<void> syncCategories(List<dynamic> categories) async {
    try {
      await _systemRef.doc('categories').set({
        'list': categories.map((c) => {
          'id': c.id,
          'name': c.name,
        }).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint('Categories synced to Firestore');
    } catch (e) {
      debugPrint('Error syncing categories: $e');
    }
  }

  /// Listen to categories from Firestore
  Stream<List<Map<String, dynamic>>> watchCategories() {
    return _systemRef.doc('categories').snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      final list = data['list'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    });
  }

  /// Update system settings in Firestore
  Future<void> syncSettings(Map<String, dynamic> settings) async {
    try {
      await _systemRef.doc('settings').set({
        ...settings,
        'updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint('System settings synced to Firestore');
    } catch (e) {
      debugPrint('Error syncing settings: $e');
    }
  }

  /// Listen to system settings from Firestore
  Stream<Map<String, dynamic>> watchSettings() {
    return _systemRef.doc('settings').snapshots().map((doc) {
      if (!doc.exists) return {};
      return doc.data() as Map<String, dynamic>;
    });
  }
}