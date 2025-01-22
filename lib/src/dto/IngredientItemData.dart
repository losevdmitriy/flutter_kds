class IngredientItemData {
  final int? id;
  final String? ingredientName;
  final String? sourceType;
  final double? amount;
  final String? expirationDate;
  final String? discontinuedAt;
  final String? discontinuedComment;
  final String? discontinuedReason;
  final String? updatedAt;
  final String? createdAt;
  final String? updatedBy;
  final String? createdBy;

  IngredientItemData({
    this.id,
    this.ingredientName,
    this.sourceType,
    this.amount,
    this.expirationDate,
    this.discontinuedAt,
    this.discontinuedComment,
    this.discontinuedReason,
    this.updatedAt,
    this.createdAt,
    this.updatedBy,
    this.createdBy,
  });

  /// Фабричный метод для десериализации из JSON
  factory IngredientItemData.fromJson(Map<String, dynamic> json) {
    return IngredientItemData(
      id: json['id'] as int?,
      ingredientName: json['ingredientName'] as String?,
      sourceType: json['sourceType'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      expirationDate: json['expirationDate'] as String?,
      discontinuedAt: json['discontinuedAt'] as String?,
      discontinuedComment: json['discontinuedComment'] as String?,
      discontinuedReason: json['discontinuedReason'] as String?,
      updatedAt: json['updatedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdBy: json['createdBy'] as String?,
    );
  }

  /// Метод для сериализации обратно в Map (при необходимости)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredientName': ingredientName,
      'sourceType': sourceType,
      'amount': amount,
      'expirationDate': expirationDate,
      'discontinuedAt': discontinuedAt,
      'discontinuedComment': discontinuedComment,
      'discontinuedReason': discontinuedReason,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'createdBy': createdBy,
    };
  }
}
