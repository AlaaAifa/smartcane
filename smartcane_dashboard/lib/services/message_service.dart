import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'base_service.dart';
import '../models/message_model.dart';

class MessageService {
  static final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref('messages');

  static Stream<List<ClientMessage>> getMessagesStream() {
    return _messagesRef.onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final List<ClientMessage> messages = [];
      data.forEach((key, value) {
        messages.add(_fromMap(key, Map<String, dynamic>.from(value)));
      });

      // Sort by date descending
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return messages;
    });
  }

  static Future<void> updateMessageStatus(String id, MessageStatus status) async {
    await _messagesRef.child(id).update({
      'status': status.name,
    });
  }

  static Future<void> sendReply({
    required String id,
    required String email,
    required String subject,
    required String body,
    required String originalMessage,
    required String staffName,
  }) async {
    // 1. Update Firebase
    await _messagesRef.child(id).update({
      'status': MessageStatus.replied.name,
      'reply_subject': subject,
      'reply_body': body,
      'replied_at': ServerValue.timestamp,
      'staff_name': staffName,
    });

    // 2. Call Backend to send email
    try {
      final response = await http.post(
        Uri.parse("${BaseService.baseUrl}/messages/reply"),
        headers: BaseService.headers,
        body: jsonEncode({
          "email": email,
          "subject": subject,
          "reply_body": body,
          "original_message": originalMessage,
        }),
      );
      
      if (response.statusCode != 200) {
        print("Backend Email Error: ${response.body}");
      }
    } catch (e) {
      print("Failed to call backend for email: $e");
    }
  }

  static Future<void> deleteMessage(String id) async {
    await _messagesRef.child(id).remove();
  }

  static ClientMessage _fromMap(String id, Map<String, dynamic> map) {
    return ClientMessage(
      id: id,
      firstname: map['firstname'] ?? '',
      lastname: map['lastname'] ?? '',
      email: map['email'] ?? '',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      status: _parseStatus(map['status']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] ?? 0),
      replySubject: map['reply_subject'],
      replyBody: map['reply_body'],
      repliedAt: map['replied_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['replied_at']) 
          : null,
      staffName: map['staff_name'],
    );
  }

  static MessageStatus _parseStatus(String? status) {
    switch (status) {
      case 'replied':
        return MessageStatus.replied;
      case 'unread':
      default:
        return MessageStatus.unread;
    }
  }
}
