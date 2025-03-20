class WriteOffRequest {
  final int id;
  final String employeeName;
  final String sourceType; // <-- Тут указываем INREDIENT / PREPACK
  final double writeOffAmount;
  final DiscontinuedReason discontinuedReason;
  final String? customReasonComment;

  WriteOffRequest({
    required this.id,
    required this.employeeName,
    required this.writeOffAmount,
    required this.discontinuedReason,
    required this.sourceType,
    this.customReasonComment,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeName': employeeName,
      'writeOffAmount': writeOffAmount,
      'discontinuedReason':
          discontinuedReason.name, // "SPOILED", "OTHER" и т.п.
      'customReasonComment': customReasonComment,
      'sourceType': sourceType
    };
  }
}

enum DiscontinuedReason {
  SPOILED,
  FINISHED,
  OTHER,
}
