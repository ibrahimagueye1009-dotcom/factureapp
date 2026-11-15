import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'models.dart';
import 'pdf_service.dart';
import 'store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.i.load();
  runApp(const App());
}

const _blue = Color(0xFF0878CF);
const _cardColors = [Color(0xFF9B3FD1), Color(0xFFFFD966), Color(0xFF0878CF), Color(0xFF1FA67A), Color(0xFFE5533D)];

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Factures',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: _blue,
          scaffoldBackgroundColor: Colors.transparent,
          cardColor: Colors.white.withOpacity(0.7),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _blue, width: 1.2),
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: _blue,
          scaffoldBackgroundColor: Colors.transparent,
          cardColor: Colors.white.withOpacity(0.08),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _blue, width: 1.2),
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        home: const Shell(),
      );
}

class Logo extends StatelessWidget {
  final String path;
  final double size;
  const Logo(this.path, {this.size = 44, super.key});
  @override
  Widget build(BuildContext context) => ClipOval(
        child: Container(
          width: size, height: size, color: Colors.white,
          child: FutureBuilder(
            future: imgBytes(path),
            builder: (_, s) => s.data == null ? Icon(Icons.business, size: size * .5, color: Colors.grey) : Image.memory(s.data!, fit: BoxFit.cover),
          ),
        ),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    const tabs = [(Icons.home_rounded, 'Accueil'), (Icons.receipt_long, 'Factures'), (Icons.business, 'Entreprises')];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF050510), Color(0xFF101018)]
                : const [Color(0xFFF8FAFF), Color(0xFFF1F5FF)],
          ),
        ),
        child: Stack(children: [
          ListenableBuilder(listenable: Store.i, builder: (_, __) => SafeArea(child: [const HomePage(), const InvoicesPage(), const CompaniesPage()][tab])),
          Positioned(
            bottom: 16 + MediaQuery.of(context).padding.bottom * .5, left: 0, right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.08)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var i = 0; i < tabs.length; i++)
                        GestureDetector(
                          onTap: () => setState(() => tab = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            decoration: BoxDecoration(color: tab == i ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                            child: Row(children: [
                              Icon(tabs[i].$1, size: 20, color: tab == i ? Colors.black : Colors.white70),
                              if (tab == i) ...[const SizedBox(width: 6), Text(tabs[i].$2, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black))],
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

void openEditor(BuildContext c, Company co, [Invoice? v]) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => InvoiceEditor(company: co, invoice: v)));
void openCompany(BuildContext c, [Company? co]) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => CompanyForm(company: co)));

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                )
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = Store.i;
    return ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 120), children: [
      const Text('Bonjour 👋', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
      const Text('Choisissez une entreprise pour créer une facture', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 18),
      SizedBox(
        height: 180,
        child: PageView(controller: PageController(viewportFraction: .9), padEnds: false, children: [
          for (var i = 0; i < s.companies.length; i++)
            GestureDetector(
              onTap: () => openEditor(context, s.companies[i]),
              child: Container(
                margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: _cardColors[i % _cardColors.length], borderRadius: BorderRadius.circular(28)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Logo(s.companies[i].logo, size: 52),
                  const Spacer(),
                  Text(s.companies[i].name, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: i % 5 == 1 ? Colors.black : Colors.white)),
                  Text('+ Nouvelle facture', style: TextStyle(color: i % 5 == 1 ? Colors.black87 : Colors.white70)),
                ]),
              ),
            ),
          GestureDetector(
            onTap: () => openCompany(context),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 1.5), borderRadius: BorderRadius.circular(28)),
              child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_business, size: 38), SizedBox(height: 8), Text('Ajouter mon entreprise', style: TextStyle(fontWeight: FontWeight.w700)),
              ])),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 22),
      const Text('Factures récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      if (s.invoices.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Aucune facture pour le moment.', style: TextStyle(color: Colors.grey)))),
      for (final v in s.invoices.take(5)) InvoiceTile(v),
    ]);
  }
}

class InvoiceTile extends StatelessWidget {
  final Invoice v;
  const InvoiceTile(this.v, {super.key});
  @override
  Widget build(BuildContext context) {
    final co = Store.i.company(v.companyId);
    return Card(
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Logo(co?.logo ?? ''),
        title: Text(v.client.isEmpty ? 'Client' : v.client, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${v.number} · ${dateFr(v.date)}'),
        trailing: Text(money(v.total), style: const TextStyle(fontWeight: FontWeight.w800)),
        onTap: co == null ? null : () => openEditor(context, co, v),
      ),
    );
  }
}

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 120), children: [
        const Text('Factures', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (Store.i.invoices.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Aucune facture enregistrée.', style: TextStyle(color: Colors.grey)))),
        for (final v in Store.i.invoices)
          Dismissible(
            key: ValueKey(v.id), direction: DismissDirection.endToStart,
            background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
            onDismissed: (_) => Store.i.deleteInvoice(v.id),
            child: InvoiceTile(v),
          ),
      ]);
}

class CompaniesPage extends StatelessWidget {
  const CompaniesPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 120), children: [
        const Text('Entreprises', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final c in Store.i.companies)
          Card(
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(leading: Logo(c.logo), title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(c.activity, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.edit_outlined), onTap: () => openCompany(context, c)),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: () => openCompany(context), icon: const Icon(Icons.add), label: const Text('Ajouter une entreprise')),
      ]);
}

Widget field(String label, TextEditingController c, {int lines = 1, TextInputType? type}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: c, maxLines: lines, keyboardType: type,
          decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
    );

class CompanyForm extends StatefulWidget {
  final Company? company;
  const CompanyForm({this.company, super.key});
  @override
  State<CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends State<CompanyForm> {
  late final Company c = widget.company ?? Company(id: DateTime.now().millisecondsSinceEpoch.toString(), name: '');
  late final k = {for (final e in ['name', 'activity', 'ninea', 'rc', 'phone', 'address', 'prefix', 'notes']) e: TextEditingController(text: _get(e))};
  String _get(String e) => {'name': c.name, 'activity': c.activity, 'ninea': c.ninea, 'rc': c.rc, 'phone': c.phone, 'address': c.address, 'prefix': c.prefix, 'notes': c.notes}[e]!;

  Future<void> pick(bool logo) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 900);
    if (x == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = '${dir.path}/${c.id}_${logo ? 'logo' : 'stamp'}_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(x.path).copy(dest);
    setState(() => logo ? c.logo = dest : c.stamp = dest);
  }

  Future<void> save() async {
    if (k['name']!.text.trim().isEmpty) return;
    c..name = k['name']!.text.trim()..activity = k['activity']!.text..ninea = k['ninea']!.text..rc = k['rc']!.text
      ..phone = k['phone']!.text..address = k['address']!.text..notes = k['notes']!.text
      ..prefix = k['prefix']!.text.trim().isEmpty ? 'FAC' : k['prefix']!.text.trim().toUpperCase();
    await Store.i.saveCompany(c);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.company == null ? 'Nouvelle entreprise' : 'Modifier l\'entreprise'), actions: [
          if (widget.company != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await Store.i.deleteCompany(c.id); if (mounted) Navigator.pop(context); }),
        ]),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          Row(children: [
            Column(children: [Logo(c.logo, size: 80), TextButton(onPressed: () => pick(true), child: const Text('Logo'))]),
            const SizedBox(width: 24),
            Column(children: [Logo(c.stamp, size: 80), TextButton(onPressed: () => pick(false), child: const Text('Tampon / signature'))]),
          ]),
          field('Nom de l\'entreprise *', k['name']!),
          field('Activité', k['activity']!),
          field('NINEA', k['ninea']!),
          field('Registre de commerce (RC)', k['rc']!),
          field('Téléphone', k['phone']!, type: TextInputType.phone),
          field('Adresse', k['address']!),
          field('Préfixe des factures (ex. SAER)', k['prefix']!),
          field('Pied de page (comptes bancaires, mentions...)', k['notes']!, lines: 3),
          FilledButton(onPressed: save, child: const Padding(padding: EdgeInsets.all(14), child: Text('Enregistrer'))),
        ]),
      );
}

class InvoiceEditor extends StatefulWidget {
  final Company company;
  final Invoice? invoice;
  const InvoiceEditor({required this.company, this.invoice, super.key});
  @override
  State<InvoiceEditor> createState() => _InvoiceEditorState();
}

class _InvoiceEditorState extends State<InvoiceEditor> {
  late final Invoice v = widget.invoice ??
      Invoice(id: DateTime.now().millisecondsSinceEpoch.toString(), companyId: widget.company.id,
          number: Store.i.nextNumber(widget.company), date: DateTime.now(), notes: 'Merci pour votre confiance.');
  late final client = TextEditingController(text: v.client), phone = TextEditingController(text: v.phone),
      address = TextEditingController(text: v.address), notes = TextEditingController(text: v.notes);

  void sync() { v.client = client.text.trim(); v.phone = phone.text; v.address = address.text; v.notes = notes.text; }

  Future<bool> save() async {
    sync();
    if (v.client.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez le nom du client.'))); return false; }
    await Store.i.saveInvoice(v);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF050510), Color(0xFF101018)]
                : const [Color(0xFFF8FAFF), Color(0xFFF1F5FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.company.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('Facture n° ${v.number}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(dateFr(v.date)),
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: v.date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (d != null) setState(() => v.date = d);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _blue.withOpacity(0.12),
                                ),
                                child: const Icon(Icons.person_outline_rounded, color: _blue),
                              ),
                              const SizedBox(width: 12),
                              const Text('Client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          field('Nom du client *', client),
                          Row(
                            children: [
                              Expanded(child: field('Téléphone', phone, type: TextInputType.phone)),
                              const SizedBox(width: 12),
                              Expanded(child: field('Adresse', address)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _blue.withOpacity(0.12),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: _blue),
                              ),
                              const SizedBox(width: 12),
                              const Text('Prestations / Produits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          for (final it in v.items)
                            Container(
                              key: ObjectKey(it),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
                                border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.04)),
                              ),
                              child: Column(
                                children: [
                                  TextFormField(
                                    initialValue: it.desc,
                                    decoration: const InputDecoration(labelText: 'Désignation'),
                                    onChanged: (t) => it.desc = t,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: '${it.qty.toInt()}',
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Qté'),
                                          onChanged: (t) => setState(() => it.qty = double.tryParse(t) ?? 0),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          initialValue: it.price == 0 ? '' : '${it.price.toInt()}',
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Prix unitaire (FCFA)'),
                                          onChanged: (t) => setState(() => it.price = double.tryParse(t) ?? 0),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded),
                                        onPressed: v.items.length > 1 ? () => setState(() => v.items.remove(it)) : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () => setState(() => v.items.add(Item())),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Ajouter une ligne'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL À PAYER', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          Text(money(v.total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _blue)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _blue.withOpacity(0.12),
                                ),
                                child: const Icon(Icons.sticky_note_2_outlined, color: _blue),
                              ),
                              const SizedBox(width: 12),
                              const Text('Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          field('Note / pied de page', notes, lines: 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.8),
              border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      side: BorderSide(color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
                    ),
                    onPressed: () async { if (await save() && mounted) Navigator.pop(context); },
                    child: const Text('Enregistrer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      backgroundColor: _blue,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Générer PDF'),
                    onPressed: () async {
                      if (!await save()) return;
                      await Printing.sharePdf(bytes: await buildPdf(widget.company, v), filename: '${v.number}.pdf');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
