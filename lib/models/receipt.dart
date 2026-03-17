class Receipt {
  final String id;
  final String? storeName;
  final double totalAmount;
  final String currency;
  final DateTime date;
  final String? category;
  final String rawText;
  final List<ReceiptItem> items;
  final DateTime createdAt;

  Receipt({
    required this.id,
    this.storeName,
    required this.totalAmount,
    this.currency = 'JPY',
    required this.date,
    this.category,
    required this.rawText,
    this.items = const [],
    required this.createdAt,
  });

  Receipt copyWith({
    String? storeName,
    double? totalAmount,
    String? currency,
    DateTime? date,
    String? category,
  }) {
    return Receipt(
      id: id,
      storeName: storeName ?? this.storeName,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      category: category ?? this.category,
      rawText: rawText,
      items: items,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeName': storeName,
        'totalAmount': totalAmount,
        'currency': currency,
        'date': date.toIso8601String(),
        'category': category,
        'rawText': rawText,
        'items': items.map((i) => i.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json['id'] as String,
        storeName: json['storeName'] as String?,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'JPY',
        date: DateTime.parse(json['date'] as String),
        category: json['category'] as String?,
        rawText: json['rawText'] as String? ?? '',
        items: (json['items'] as List?)
                ?.map((i) => ReceiptItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class ReceiptItem {
  final String name;
  final double price;
  final int quantity;

  ReceiptItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int? ?? 1,
      );
}
