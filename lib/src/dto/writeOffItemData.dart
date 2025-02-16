class WriteOffItemData {
  int? id;
  String? sourceType;
  String? name;
  int? sourceId;
  double? amount;
  String? discontinuedComment;
  String? discontinuedReason;
  bool? isCompleted;
  String? createdBy;
  String? createdAt;

  WriteOffItemData({
    this.id,
    this.sourceType,
    this.name,
    this.sourceId,
    this.amount,
    this.discontinuedComment,
    this.discontinuedReason,
    this.isCompleted,
    this.createdBy,
    this.createdAt,
  });

  // Преобразование из JSON
  factory WriteOffItemData.fromJson(Map<String, dynamic> json) {
    return WriteOffItemData(
      id: json['id'] as int?,
      sourceType: json['sourceType'] as String?,
      name: json['name'] as String?,
      sourceId: json['sourceId'] as int?,
      amount: (json['amount'] as num?)?.toDouble(),
      discontinuedComment: json['discontinuedComment'] as String?,
      discontinuedReason: json['discontinuedReason'] as String?,
      isCompleted: json['isCompleted'] as bool?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  // Преобразование в объект
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceType': sourceType,
      'name': name,
      'sourceId': sourceId,
      'amount': amount,
      'discontinuedComment': discontinuedComment,
      'discontinuedReason': discontinuedReason,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
      'createdAt': createdAt
    };
  }
}
