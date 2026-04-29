class SyncActionModel {
  final String idempotencyKey;
  final String type;
  final Map<String, dynamic> payload;
  final int retryCount;

  SyncActionModel({
    required this.idempotencyKey,
    required this.type,
    required this.payload,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'idempotencyKey': idempotencyKey,
      'type': type,
      'payload': payload,
      'retryCount': retryCount,
    };
  }

  factory SyncActionModel.fromMap(Map<String, dynamic> map) {
    return SyncActionModel(
      idempotencyKey: map['idempotencyKey'],
      type: map['type'],
      payload: Map<String, dynamic>.from(map['payload']),
      retryCount: map['retryCount'] ?? 0,
    );
  }
}