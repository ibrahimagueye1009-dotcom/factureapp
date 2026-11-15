class InvoiceItem {
  String desc;
  double qty;
  double price;

  InvoiceItem({this.desc = '', this.qty = 1, this.price = 0});

  double get total => qty * price;

  Map<String, dynamic> toJson() => {'desc': desc, 'qty': qty, 'price': price};

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
        desc: (j['desc'] ?? '').toString(),
        qty: (j['qty'] as num?)?.toDouble() ?? 0,
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );
}

class Invoice {
  String id;
  String companyId;
  String number;
  String date; // yyyy-MM-dd
  String clientName;
  String clientPhone;
  String clientEmail;
  String clientAddress;
  String currency;
  String paymentMode;
  String notes;
  List<InvoiceItem> items;
  DateTime updatedAt;

  Invoice({
    required this.id,
    required this.companyId,
    required this.number,
    required this.date,
    this.clientName = '',
    this.clientPhone = '',
    this.clientEmail = '',
    this.clientAddress = '',
    this.currency = 'FCFA',
    this.paymentMode = '',
    this.notes = '',
    List<InvoiceItem>? items,
    DateTime? updatedAt,
  })  : items = items ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  double get total => items.fold(0.0, (s, i) => s + i.total);

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'number': number,
        'date': date,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'clientEmail': clientEmail,
        'clientAddress': clientAddress,
        'currency': currency,
        'paymentMode': paymentMode,
        'notes': notes,
        'items': items.map((e) => e.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: j['id'].toString(),
        companyId: (j['companyId'] ?? 'dte').toString(),
        number: (j['number'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        clientName: (j['clientName'] ?? '').toString(),
        clientPhone: (j['clientPhone'] ?? '').toString(),
        clientEmail: (j['clientEmail'] ?? '').toString(),
        clientAddress: (j['clientAddress'] ?? '').toString(),
        currency: (j['currency'] ?? 'FCFA').toString(),
        paymentMode: (j['paymentMode'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        items: ((j['items'] ?? []) as List)
            .map((e) => InvoiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        updatedAt: DateTime.tryParse((j['updatedAt'] ?? '').toString()),
      );
}
