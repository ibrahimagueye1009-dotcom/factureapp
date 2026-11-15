import 'package:flutter/material.dart';

import '../companies.dart';
import '../models.dart';
import '../services/profile.dart';
import '../services/store.dart';
import '../utils.dart';
import 'invoice_editor.dart';

/// Liste des factures. Si [company] est null : toutes les entreprises.
class InvoiceListView extends StatefulWidget {
  final Company? company;
  const InvoiceListView({super.key, this.company});

  @override
  State<InvoiceListView> createState() => _InvoiceListViewState();
}

class _InvoiceListViewState extends State<InvoiceListView> {
  List<Invoice>? _items;
  Map<String, Company> _companies = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await InvoiceStore.all(companyId: widget.company?.id);
    final companies = <String, Company>{};
    for (final id in l.map((invoice) => invoice.companyId).toSet()) {
      companies[id] = await ProfileStore.company(id);
    }
    if (mounted) {
      setState(() {
        _items = l;
        _companies = companies;
      });
    }
  }

  Future<void> _open(Invoice inv) async {
    final company =
        _companies[inv.companyId] ?? await ProfileStore.company(inv.companyId);
    if (!mounted) return;
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                InvoiceEditorScreen(company: company, invoice: inv)));
    _load();
  }

  Future<void> _delete(Invoice inv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la facture ?'),
        content: Text('La facture N° ${inv.number} sera supprimée.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      await InvoiceStore.delete(inv.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Aucune facture pour le moment.\nCréez la première avec « Nouvelle facture ».',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF697789), height: 1.5),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final inv = items[i];
        final co = _companies[inv.companyId] ?? companyById(inv.companyId);
        return Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: ListTile(
            onTap: () => _open(inv),
            leading: CircleAvatar(
              backgroundColor: Color(co.color).withOpacity(0.12),
              child: Icon(Icons.description_outlined, color: Color(co.color)),
            ),
            title: Text(inv.clientName.isEmpty ? '(sans nom)' : inv.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${inv.number} · ${dateLabel(inv.date)}'
                '${widget.company == null ? ' · ${co.name}' : ''}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(money(inv.total, inv.currency),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFF102B50))),
              IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _delete(inv)),
            ]),
          ),
        );
      },
    );
  }
}
