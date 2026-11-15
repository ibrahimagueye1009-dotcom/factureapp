import 'package:flutter/material.dart';

import '../companies.dart';
import 'invoice_editor.dart';
import 'invoice_list.dart';

class CompanyScreen extends StatefulWidget {
  final Company company;
  const CompanyScreen({super.key, required this.company});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  int _rev = 0;

  Future<void> _new() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => InvoiceEditorScreen(company: widget.company)));
    if (mounted) setState(() => _rev++);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.company;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(c.color),
        foregroundColor: Colors.white,
        title: Text(c.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(c.color),
        foregroundColor: Colors.white,
        onPressed: _new,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle facture'),
      ),
      body: InvoiceListView(key: ValueKey(_rev), company: c),
    );
  }
}
