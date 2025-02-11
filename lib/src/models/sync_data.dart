import 'dart:convert';

enum SyncStatus {
  synced,
  unsynced,
  pending,
  conflict,
}

class SyncData {
  final String id;
  final String key;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? previousData;
  final DateTime createdAt;
  final DateTime updatedAt;
  SyncStatus status;

  SyncData({
    required this.id,
    required this.key,
    required this.data,
    this.previousData,
    required this.createdAt,
    required this.updatedAt,
    this.status = SyncStatus.unsynced,
  });

  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      id: json['id'],
      key: json['key'],
      data: jsonDecode(json['data']),
      previousData: json.containsKey('previousData')
          ? jsonDecode(json['previousData'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      status: SyncStatus.values.firstWhere(
        (e) => e.toString() == 'SyncStatus.${json['status']}',
        orElse: () => SyncStatus.unsynced,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'data': jsonEncode(data),
      'previousData': jsonEncode(previousData),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }

  SyncData copyWith({
    String? id,
    String? key,
    Map<String, dynamic>? data,
    Map<String, dynamic>? previousData,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? status,
  }) {
    return SyncData(
      id: id ?? this.id,
      key: key ?? this.key,
      data: data ?? this.data,
      previousData: previousData ?? this.previousData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          key == other.key &&
          data.toString() == other.data.toString() &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      key.hashCode ^
      data.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      status.hashCode;
}
