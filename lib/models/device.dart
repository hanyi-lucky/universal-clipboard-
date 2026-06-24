class Device {
  final String id;
  final String name;
  final String platform;
  final DateTime lastSeen;

  const Device({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastSeen,
  });

  Device copyWith({
    String? id,
    String? name,
    String? platform,
    DateTime? lastSeen,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'platform': platform,
    'lastSeen': lastSeen.toIso8601String(),
  };

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'] as String,
      name: map['name'] as String,
      platform: map['platform'] as String,
      lastSeen: DateTime.parse(map['lastSeen'] as String),
    );
  }
}
