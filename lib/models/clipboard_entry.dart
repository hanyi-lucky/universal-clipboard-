import 'dart:convert';
import 'package:crypto/crypto.dart';

enum ContentType {
  text,
  image,
  file,
}

class ClipboardEntry {
  final String id;
  final String content;
  final String sourceDeviceId;
  final String sourceDeviceName;
  final DateTime timestamp;
  final ContentType type;
  final bool isPinned;

  const ClipboardEntry({
    required this.id,
    required this.content,
    required this.sourceDeviceId,
    required this.sourceDeviceName,
    required this.timestamp,
    required this.type,
    this.isPinned = false,
  });

  String get contentHash =>
      sha256.convert(utf8.encode(content)).toString();

  ClipboardEntry copyWith({
    String? id,
    String? content,
    String? sourceDeviceId,
    String? sourceDeviceName,
    DateTime? timestamp,
    ContentType? type,
    bool? isPinned,
  }) {
    return ClipboardEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      sourceDeviceName: sourceDeviceName ?? this.sourceDeviceName,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'sourceDeviceId': sourceDeviceId,
    'sourceDeviceName': sourceDeviceName,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'isPinned': isPinned,
  };

  factory ClipboardEntry.fromMap(Map<String, dynamic> map) {
    return ClipboardEntry(
      id: map['id'] as String,
      content: map['content'] as String,
      sourceDeviceId: map['sourceDeviceId'] as String,
      sourceDeviceName: map['sourceDeviceName'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: ContentType.values.firstWhere((e) => e.name == map['type']),
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipboardEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
