import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Eşsiz Sohbet Odası ID'si Üretme (Örn: ali_veli ile veli_ali aynı odayı açmalı)
  String _getChatRoomId(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort(); // Alfabetik sırala ki kim kime atarsa atsın aynı ID çıksın
    return ids.join("_");
  }

  // 2. Mesaj Gönderme
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    // Mesaj Paketi
    Map<String, dynamic> newMessage = {
      'senderId': currentUserId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
    };

    // İki kullanıcının ortak oda ID'sini bul
    String chatRoomId = _getChatRoomId(currentUserId, receiverId);

    await _firestore.collection('chat_rooms').doc(chatRoomId).set(
      {
        'participants': [currentUserId, receiverId],
        'lastMessage': message,
        'timestamp': timestamp,
      },
      SetOptions(merge: true),
    ); // merge: true sayesinde var olan veriyi silmez, üstüne yazar

    // Firestore'a kaydet (chat_rooms -> ODA_ID -> messages -> MESAJ_ID)
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage);
  }

  // 3. Mesajları Çekme (Stream ile anlık dinleme)
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    String chatRoomId = _getChatRoomId(userId, otherUserId);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Eskiden yeniye sırala
        .snapshots();
  }
}
