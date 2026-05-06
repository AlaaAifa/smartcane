enum MessageStatus {
  unread,
  replied
}

class ClientMessage {
  final String id;
  final String firstname;
  final String lastname;
  final String email;
  final String subject;
  final String message;
  final MessageStatus status;
  final DateTime createdAt;
  
  // Reply details
  final String? replySubject;
  final String? replyBody;
  final DateTime? repliedAt;
  final String? staffName;

  ClientMessage({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.replySubject,
    this.replyBody,
    this.repliedAt,
    this.staffName,
  });

  String get fullName => "$firstname $lastname";

  ClientMessage copyWith({
    MessageStatus? status,
    String? replySubject,
    String? replyBody,
    DateTime? repliedAt,
    String? staffName,
  }) {
    return ClientMessage(
      id: id,
      firstname: firstname,
      lastname: lastname,
      email: email,
      subject: subject,
      message: message,
      status: status ?? this.status,
      createdAt: createdAt,
      replySubject: replySubject ?? this.replySubject,
      replyBody: replyBody ?? this.replyBody,
      repliedAt: repliedAt ?? this.repliedAt,
      staffName: staffName ?? this.staffName,
    );
  }
}
