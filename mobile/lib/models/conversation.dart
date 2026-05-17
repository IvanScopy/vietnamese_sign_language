enum ConversationRole {
  signer,
  speaker;

  String get storageValue => name;

  String get label {
    switch (this) {
      case ConversationRole.signer:
        return 'Signer';
      case ConversationRole.speaker:
        return 'Speaker';
    }
  }

  static ConversationRole fromStorage(String value) {
    return ConversationRole.values.firstWhere(
      (role) => role.storageValue == value,
      orElse: () => ConversationRole.signer,
    );
  }
}

enum ConversationMessageSource {
  recognition,
  speech,
  manual;

  String get storageValue => name;

  String get label {
    switch (this) {
      case ConversationMessageSource.recognition:
        return 'Recognition';
      case ConversationMessageSource.speech:
        return 'Speech';
      case ConversationMessageSource.manual:
        return 'Manual';
    }
  }

  static ConversationMessageSource fromStorage(String value) {
    return ConversationMessageSource.values.firstWhere(
      (source) => source.storageValue == value,
      orElse: () => ConversationMessageSource.manual,
    );
  }
}

enum ConversationMessageStatus {
  draft,
  confirmed;

  String get storageValue => name;

  static ConversationMessageStatus fromStorage(String value) {
    return ConversationMessageStatus.values.firstWhere(
      (status) => status.storageValue == value,
      orElse: () => ConversationMessageStatus.draft,
    );
  }
}

class ConversationMessage {
  final String id;
  final ConversationRole role;
  final ConversationMessageSource source;
  final ConversationMessageStatus status;
  final String text;
  final DateTime timestamp;
  final double? confidence;

  const ConversationMessage({
    required this.id,
    required this.role,
    required this.source,
    required this.status,
    required this.text,
    required this.timestamp,
    this.confidence,
  });

  bool get isConfirmed => status == ConversationMessageStatus.confirmed;

  bool get isLowConfidence =>
      source == ConversationMessageSource.recognition &&
      confidence != null &&
      confidence! < 0.6;

  ConversationMessage copyWith({
    String? id,
    ConversationRole? role,
    ConversationMessageSource? source,
    ConversationMessageStatus? status,
    String? text,
    DateTime? timestamp,
    double? confidence,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      source: source ?? this.source,
      status: status ?? this.status,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.storageValue,
      'source': source.storageValue,
      'status': status.storageValue,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      if (confidence != null) 'confidence': confidence,
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String,
      role: ConversationRole.fromStorage(json['role'] as String? ?? ''),
      source: ConversationMessageSource.fromStorage(
        json['source'] as String? ?? '',
      ),
      status: ConversationMessageStatus.fromStorage(
        json['status'] as String? ?? '',
      ),
      text: json['text'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

class ConversationSession {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<ConversationMessage> messages;

  const ConversationSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.messages,
  });

  List<ConversationMessage> get confirmedMessages =>
      messages.where((message) => message.isConfirmed).toList();

  bool get hasConfirmedMessages => confirmedMessages.isNotEmpty;

  String get preview {
    final text = confirmedMessages
        .map((message) => message.text.trim())
        .where((text) => text.isNotEmpty)
        .take(3)
        .join(' / ');

    if (text.isEmpty) {
      return 'No confirmed messages';
    }

    return text.length <= 96 ? text : '${text.substring(0, 93)}...';
  }

  ConversationSession copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    List<ConversationMessage>? messages,
  }) {
    return ConversationSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
              .whereType<Map>()
              .map(
                (message) => ConversationMessage.fromJson(
                  Map<String, dynamic>.from(message),
                ),
              )
              .toList()
        : <ConversationMessage>[];

    return ConversationSession(
      id: json['id'] as String,
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endedAt: DateTime.tryParse(json['endedAt'] as String? ?? ''),
      messages: messages,
    );
  }
}
