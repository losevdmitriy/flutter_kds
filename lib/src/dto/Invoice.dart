class Invoice {
  final int? id;
  DateTime date;
  String vendor;
  List<InvoiceItem> items;
  int? totalItems;
  double? totalCost;

  Invoice({
    this.id,
    required this.date,
    required this.vendor,
    this.totalItems,
    this.totalCost,
    List<InvoiceItem>? items,
  }) : items = items ?? [];

  int get totalAmount => items.fold(0, (sum, item) => sum + item.amount);

  double get totalPrice =>
      totalCost ??
      items.fold(0.0, (sum, item) => sum + (item.amount * item.price));

  int get totalLines => totalItems ?? items.length;

  factory Invoice.getAllFromJson(Map<String, dynamic> json) {
    return Invoice(
        id: json['id'],
        date: DateTime.parse(json['date']),
        vendor: json['vendor'],
        totalItems: json['totalItems'],
        totalCost: json['totalCost']);
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      date: DateTime.parse(json['date']),
      vendor: json['vendor'],
      items: (json['itemDataList'] as List)
          .map((item) => InvoiceItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'vendor': vendor,
      'itemDataList': items.map((item) => item.toJson()).toList(),
    };
  }
}

class InvoiceItem {
  final int? id;
  int? sourceId;
  String? sourceType;
  String name;
  int amount;
  double price;

  InvoiceItem({
    this.id,
    this.sourceId,
    this.sourceType,
    required this.name,
    required this.amount,
    required this.price,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'],
      sourceId: json['sourceId'],
      sourceType: json['sourceType'],
      name: json['name'],
      amount: json['amount'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'sourceType': sourceType,
      'name': name,
      'amount': amount,
      'price': price,
    };
  }

  double get lineTotal => amount * price;
}
