import 'package:intl/intl.dart';

String money(double v) =>
    '${NumberFormat.decimalPattern('fr_FR').format(v).replaceAll(RegExp('[\u202f\u00a0]'), ' ')} FCFA';
String dateFr(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

class Company {
  String id, name, activity, ninea, rc, phone, address, notes, logo, stamp, prefix;
  Company({required this.id, required this.name, this.activity = '', this.ninea = '', this.rc = '',
      this.phone = '', this.address = '', this.notes = '', this.logo = '', this.stamp = '', this.prefix = 'FAC'});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'activity': activity, 'ninea': ninea, 'rc': rc,
        'phone': phone, 'address': address, 'notes': notes, 'logo': logo, 'stamp': stamp, 'prefix': prefix};
  factory Company.fromJson(Map j) => Company(id: j['id'], name: j['name'], activity: j['activity'] ?? '',
      ninea: j['ninea'] ?? '', rc: j['rc'] ?? '', phone: j['phone'] ?? '', address: j['address'] ?? '',
      notes: j['notes'] ?? '', logo: j['logo'] ?? '', stamp: j['stamp'] ?? '', prefix: j['prefix'] ?? 'FAC');
}

class Item {
  String desc;
  double qty, price;
  Item({this.desc = '', this.qty = 1, this.price = 0});
  double get total => qty * price;
  Map<String, dynamic> toJson() => {'desc': desc, 'qty': qty, 'price': price};
  factory Item.fromJson(Map j) => Item(desc: j['desc'], qty: (j['qty'] as num).toDouble(), price: (j['price'] as num).toDouble());
}

class Invoice {
  String id, companyId, number, client, phone, address, notes;
  DateTime date;
  List<Item> items;
  Invoice({required this.id, required this.companyId, required this.number, required this.date,
      this.client = '', this.phone = '', this.address = '', this.notes = '', List<Item>? items})
      : items = items ?? [Item()];
  double get total => items.fold(0, (s, i) => s + i.total);
  Map<String, dynamic> toJson() => {'id': id, 'companyId': companyId, 'number': number, 'date': date.toIso8601String(),
        'client': client, 'phone': phone, 'address': address, 'notes': notes, 'items': items.map((e) => e.toJson()).toList()};
  factory Invoice.fromJson(Map j) => Invoice(id: j['id'], companyId: j['companyId'], number: j['number'],
      date: DateTime.parse(j['date']), client: j['client'] ?? '', phone: j['phone'] ?? '', address: j['address'] ?? '',
      notes: j['notes'] ?? '', items: (j['items'] as List).map((e) => Item.fromJson(e)).toList());
}
