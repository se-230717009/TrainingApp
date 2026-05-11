/// lib/services/chat_service.dart
///
/// Concrete implementation of [IChatService] backed by Cloud Firestore.
///
/// **Responsibilities:**
///   - Generating deterministic chat-room IDs so two users always share
///     the same room regardless of who initiates the conversation.
///   - Sending messages and updating the room preview document atomically.
///   - Streaming messages in chronological order.

library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'interfaces/i_chat_service.dart';

/// Firebase-backed implementation of [IChatService].
class ChatService implements IChatService {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  /// Firestore instance — injectable so tests can pass a fake.
  final FirebaseFirestore _firestore;

  /// Firebase Auth instance — used to identify the current sender.
  final FirebaseAuth _auth;

  /// Creates a [ChatService].
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Generates a deterministic chat-room ID for any two users.
  ///
  /// Sorting the UIDs alphabetically before joining ensures that
  /// `_getChatRoomId(A, B)` == `_getChatRoomId(B, A)`, so both participants
  /// always land in the same Firestore document regardless of who opens the
  /// conversation first.
  String _getChatRoomId(String userId, String otherUserId) {
    final ids = [userId, otherUserId]..sort();
    return ids.join('_');
  }

  // ---------------------------------------------------------------------------
  // IChatService
  // ---------------------------------------------------------------------------

  @override
  Future<void> sendMessage(String receiverId, String message) async {
    final String senderId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();
    final String chatRoomId = _getChatRoomId(senderId, receiverId);

    // 1. Update (or create) the room document with the latest message preview.
    //    Using `merge: true` so existing room metadata is preserved.
    await _firestore.collection('chat_rooms').doc(chatRoomId).set(
      {
        'participants': [senderId, receiverId],
        'lastMessage': message,
        'timestamp': timestamp,
      },
      SetOptions(merge: true),
    );

    // 2. Add the full message to the room's messages subcollection.
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
    });
  }

  @override
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    final String chatRoomId = _getChatRoomId(userId, otherUserId);
    // Order oldest-first so new messages appear at the bottom of the list.
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
