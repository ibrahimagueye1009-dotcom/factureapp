import 'package:flutter/material.dart';

import '../companies.dart';
import '../models.dart';
import '../services/store.dart';
import '../utils.dart';
import 'pdf_screen.dart';

class _ItemCtrl {
  final TextEditingController desc;
  final TextEditingController qty;
  final TextEditingController price;
  _ItemCtrl(InvoiceItem i)
      : desc = TextEditingController(text: i.desc),
        qty = TextEditingController(text: i.qty == 0 ? '' : fmtPlain(i.qty)),
        price =
            TextEditingController(text: i.price == 0 ? '' : fmtPlain(i.price));

  static String fmtPlain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  InvoiceItem toItem() => InvoiceItem(
      desc: desc.text.trim(),
      qty: parseNum(qty.text),
      price: parseNum(price.text));

  void dispose() {
    desc.dispose();
    qty.dispose();
    price.dispose();
  }
}

class InvoiceEditorScreen extends StatefulWidget {
  final Company company;
  final Invoice? invoice;
  const InvoiceEditorScreen({super.key, required this.company, this.invoice});

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  static const _payments = [
    '',
    'Espèces',
    'Wave',
    'Orange Money',
    'Virement bancaire',
    'Chèque',
  ];

  late final String _id;
  final _num = TextEditingController();
  final _client = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _addr = TextEditingController();
  final _notes = TextEditingController();
  final List<_ItemCtrl> _items = [];
  late DateTime _date;
  late String _currency;
  String _payment = '';

  Company get c => widget.company;

  @override
  void initState() {
    super.initState();
    final inv = widget.invoice;
    if (inv != null) {
      _id = inv.id;
      _num.text = inv.number;
      _client.text = inv.clientName;
      _phone.text = inv.clientPhone;
      _email.text = inv.clientEmail;
      _addr.text = inv.clientAddress;
      _notes.text = inv.notes;
      _currency = inv.currency;
      _payment = _payments.contains(inv.paymentMode) ? inv.paymentMode : '';
      _date = DateTime.tryParse(inv.date) ?? DateTime.now();
      for (final i in inv.items) {
        _items.add(_ItemCtrl(i));
      }
      if (_items.isEmpty) _items.add(_ItemCtrl(InvoiceItem()));
    } else {
      _id = '${c.id}-${DateTime.now().millisecondsSinceEpoch}';
      _currency = c.currencies.first;
      _date = DateTime.now();
      _notes.text = c.invoiceTerms.isNotEmpty
          ? c.invoiceTerms
          : c.extendedFields
              ? 'Merci pour votre confiance.'
              : '';
      _items.add(_ItemCtrl(InvoiceItem()));
      InvoiceStore.nextNumber(c).then((n) {
        if (mounted) setState(() => _num.text = n);
      });
    }
  }

  @override
  void dispose() {
    for (final t in [_num, _client, _phone, _email, _addr, _notes]) {
      t.dispose();
    }
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  double get _total => _items.fold(0.0, (s, i) {
        final it = i.toItem();
        return s + it.total;
      });

  Invoice _collect() => Invoice(
        id: _id,
        companyId: c.id,
        number: _num.text.trim(),
        date: toIso(_date),
        clientName: _client.text.trim(),
        clientPhone: _phone.text.trim(),
        clientEmail: _email.text.trim(),
        clientAddress: _addr.text.trim(),
        currency: _currency,
        paymentMode: _payment,
        notes: _notes.text.trim(),
        items: _items
            .map((e) => e.toItem())
            .where((i) => i.desc.isNotEmpty)
            .toList(),
      );

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<Invoice?> _validateAndSave() async {
    final inv = _collect();
    if (inv.number.isEmpty) {
      _toast('Veuillez saisir un numéro de facture.');
      return null;
    }
    if (inv.clientName.isEmpty) {
      _toast('Ajoutez le nom du client pour continuer.');
      return null;
    }
    if (inv.items.isEmpty) {
      _toast('Ajoutez au moins un produit ou une prestation.');
      return null;
    }
    await InvoiceStore.save(inv);
    return inv;
  }

  Future<void> _save() async {
    final inv = await _validateAndSave();
    if (inv == null || !mounted) return;
    _toast('Facture N° ${inv.number} enregistrée.');
  }

  Future<void> _pdf() async {
    final inv = await _validateAndSave();
    if (inv == null || !mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => PdfScreen(invoice: inv, company: c)));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Widget _card(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF102B50))),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  Widget _gap() => const SizedBox(height: 12);

  Widget _itemCard(int i) {
    final it = _items[i];
    final line = it.toItem().total;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: Text('Produit / prestation ${i + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline, color: Color(0xFFB42318)),
            onPressed: _items.length > 1
                ? () => setState(() => _items.removeAt(i).dispose())
                : null,
          ),
        ]),
        TextField(
          controller: it.desc,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              labelText: 'Désignation',
              hintText: 'Ex. : Réparation climatiseur'),
          onChanged: (_) => setState(() {}),
        ),
        _gap(),
        Row(children: [
          Expanded(
            child: TextField(
              controller: it.qty,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantité'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: it.price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Prix unitaire'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ]),
        _gap(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Montant de la ligne'),
          Text(money(line, _currency),
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(c.color);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(widget.invoice == null
            ? 'Nouvelle facture'
            : 'Modifier la facture'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card('Informations du client', [
            TextField(
              controller: _client,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Nom complet / entreprise *'),
            ),
            if (c.extendedFields) ...[
              _gap(),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                  ),
                ),
              ]),
              _gap(),
              TextField(
                controller: _addr,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Adresse du client'),
              ),
            ],
          ]),
          _card('Détails de la facture', [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _num,
                  decoration: const InputDecoration(labelText: 'N° facture'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(dateLabel(toIso(_date))),
                  ),
                ),
              ),
            ]),
            if (c.currencies.length > 1) ...[
              _gap(),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Devise'),
                items: [
                  for (final cu in c.currencies)
                    DropdownMenuItem(value: cu, child: Text(cu)),
                ],
                onChanged: (v) => setState(() => _currency = v ?? _currency),
              ),
            ],
          ]),
          _card('Produits / prestations', [
            for (var i = 0; i < _items.length; i++) _itemCard(i),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _items.add(_ItemCtrl(InvoiceItem()))),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un produit ou service'),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total à payer',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(money(_total, _currency),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Color(0xFF102B50))),
                  ]),
            ),
          ]),
          if (c.extendedFields)
            _card('Règlement', [
              DropdownButtonFormField<String>(
                value: _payment,
                decoration:
                    const InputDecoration(labelText: 'Mode de paiement'),
                items: [
                  for (final p in _payments)
                    DropdownMenuItem(
                        value: p, child: Text(p.isEmpty ? 'À préciser' : p)),
                ],
                onChanged: (v) => setState(() => _payment = v ?? ''),
              ),
              _gap(),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Note (facultatif)'),
              ),
            ]),
          const SizedBox(height: 70),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _save,
                child: const Text('Enregistrer'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _pdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Générer le PDF'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
