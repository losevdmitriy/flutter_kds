class PrepackItemData {
  int? id;
  String? prepackName;
  String? sourceType;
  double? amount;
  String? expirationDate;
  String? discontinuedAt;
  String? discontinuedComment;
  String? discontinuedReason;

  PrepackItemData({
    this.id,
    this.prepackName,
    this.sourceType,
    this.amount,
    this.expirationDate,
    this.discontinuedAt,
    this.discontinuedComment,
    this.discontinuedReason,
  });

  factory PrepackItemData.fromJson(Map<String, dynamic> json) {
    return PrepackItemData(
      id: json['id'] as int?,
      prepackName: json['prepackName'] as String?,
      sourceType: json['sourceType'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      expirationDate: json['expirationDate'] as String?,
      discontinuedAt: json['discontinuedAt'] as String?,
      discontinuedComment: json['discontinuedComment'] as String?,
      discontinuedReason: json['discontinuedReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prepackName': prepackName,
      'sourceType': sourceType,
      'amount': amount,
      'expirationDate': expirationDate,
      'discontinuedAt': discontinuedAt,
      'discontinuedComment': discontinuedComment,
      'discontinuedReason': discontinuedReason,
    };
  }
}
