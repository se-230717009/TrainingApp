/// lib/services/interfaces/i_chat_service.dart
///
/// Abstract contract for real-time chat operations.
///
/// Decouples chat screens from the concrete [ChatService] implementation,
/// making it straightforward to replace Firebase with another backend or
/// to inject a stub during testing.

library;
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class IChatService {
  /// Sends a [message] from the currently authenticated user to [receiverId].
  ///
  /// This also updates (or creates) the shared `chat_rooms` document with
  /// the latest message preview so the messages list screen stays in sync.
  Future<void> sendMessage(String receiverId, String message);

  /// Returns a real-time stream of all messages exchanged between
  /// [userId] and [otherUserId], ordered oldest-first.
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId);
}
