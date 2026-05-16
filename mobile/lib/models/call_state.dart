/// Call state enum representing the lifecycle of a video call.
enum CallState {
  ringing,
  active,
  ended,
  rejected,
  cancelled,
  missed,
  busy,
  failed;

  String get label {
    switch (this) {
      case CallState.ringing:
        return 'Ringing';
      case CallState.active:
        return 'Active';
      case CallState.ended:
        return 'Ended';
      case CallState.rejected:
        return 'Rejected';
      case CallState.cancelled:
        return 'Cancelled';
      case CallState.missed:
        return 'Missed';
      case CallState.busy:
        return 'Busy';
      case CallState.failed:
        return 'Failed';
    }
  }

  bool get isTerminal =>
      this == ended ||
      this == rejected ||
      this == cancelled ||
      this == missed ||
      this == busy ||
      this == failed;
}

/// Represents a video call session.
class CallSession {
  final int callId;
  final String roomName;
  final int fromUserId;
  final String? fromUserName;
  final CallState state;
  final DateTime? expiresAt;
  final String? token;

  CallSession({
    required this.callId,
    required this.roomName,
    required this.fromUserId,
    this.fromUserName,
    this.state = CallState.ringing,
    this.expiresAt,
    this.token,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      callId: json['callId'] as int? ?? json['id'] as int? ?? 0,
      roomName: json['roomName'] as String? ?? '',
      fromUserId: json['fromUserId'] as int? ?? json['callerId'] as int? ?? 0,
      fromUserName: json['fromUserName'] as String?,
      state: _parseCallState(json['state'] as String?),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'roomName': roomName,
      'fromUserId': fromUserId,
      if (fromUserName != null) 'fromUserName': fromUserName,
      'state': state.name,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      if (token != null) 'token': token,
    };
  }

  CallSession copyWith({
    int? callId,
    String? roomName,
    int? fromUserId,
    String? fromUserName,
    CallState? state,
    DateTime? expiresAt,
    String? token,
  }) {
    return CallSession(
      callId: callId ?? this.callId,
      roomName: roomName ?? this.roomName,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      state: state ?? this.state,
      expiresAt: expiresAt ?? this.expiresAt,
      token: token ?? this.token,
    );
  }

  static CallState _parseCallState(String? raw) {
    if (raw == null) return CallState.ringing;
    for (final state in CallState.values) {
      if (state.name == raw) return state;
    }
    return CallState.ringing;
  }

  @override
  String toString() {
    return 'CallSession(callId: $callId, roomName: $roomName, fromUserId: $fromUserId, state: $state)';
  }
}
