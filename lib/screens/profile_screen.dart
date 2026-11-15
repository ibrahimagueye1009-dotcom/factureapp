import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../companies.dart';
import '../services/account.dart';
import '../services/profile.dart';
import '../services/store.dart';
import '../utils.dart';
import '../widgets/company_logo.dart';

/// « Mon profil entreprise » : nom, logo, tampon, activités,
/// coordonnées bancaires, pied de page… comme sur les modèles.
class ProfileScreen extends StatefulWidget {
  final Company initialCompany;
  final VoidCallback onChanged;
  final VoidCallback? onLogout;
  final bool isNew;
  const ProfileScreen(
      {super.key,
      required this.initialCompany,
      required this.onChanged,
      this.onLogout,
      this.isNew = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Company _current;
  bool _busy = false;
  late bool _isNew;
  List<Company> _companies = [];

  final _name = TextEditingController();
  final _displayName = TextEditingController();
  final _subtitle = TextEditingController();
  final _taxIdLabel = TextEditingController();
  final _taxId = TextEditingController();
  final _rccm = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _currencies = TextEditingController();
  final _invoiceTerms = TextEditingController();
  final _banner = TextEditingController();
  final _details = TextEditingController();
  final _footer = TextEditingController();
  final _bank = TextEditingController();
  InvoiceStyle _style = InvoiceStyle.modern;

  @override
  void initState() {
    super.initState();
    _current = widget.initialCompany;
    _isNew = widget.isNew;
    _loadFields();
    _refreshCompanies();
  }

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    _subtitle.dispose();
    _taxIdLabel.dispose();
    _taxId.dispose();
    _rccm.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _currencies.dispose();
    _invoiceTerms.dispose();
    _banner.dispose();
    _details.dispose();
    _footer.dispose();
    _bank.dispose();
    super.dispose();
  }

  void _loadFields() {
    _name.text = _current.name;
    _displayName.text = _current.displayName;
    _subtitle.text = _current.subtitle;
    _taxIdLabel.text = _current.taxIdLabel;
    _taxId.text = _current.taxId;
    _rccm.text = _current.rccm;
    _address.text = _current.address;
    _phone.text = _current.phone;
    _email.text = _current.email;
    _currencies.text = _current.currencies.join(', ');
    _invoiceTerms.text = _current.invoiceTerms;
    _style = _current.style;
    _banner.text = _current.bannerLines.join('\n');
    _details.text = _current.detailLines.join('\n');
    _footer.text = _current.footerLines.join('\n');
    _bank.text =
        [for (final b in _current.bankLines) '${b.$1} : ${b.$2}'].join('\n');
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _refreshCompanies() async {
    final companies = await ProfileStore.companies();
    if (!mounted) return;
    setState(() => _companies = companies);
  }

  Company _collect() {
    final currencies = _currencies.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    return _current.copyWith(
      name: _name.text.trim(),
      displayName: _displayName.text.trim(),
      subtitle: _subtitle.text.trim(),
      prefix: _isNew
          ? Company.custom(id: _current.id, name: _name.text.trim()).prefix
          : _current.prefix,
      style: _style,
      taxIdLabel: _taxIdLabel.text.trim().isEmpty
          ? 'Identifiant fiscal'
          : _taxIdLabel.text.trim(),
      taxId: _taxId.text.trim(),
      rccm: _rccm.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      invoiceTerms: _invoiceTerms.text.trim(),
      currencies: currencies.isEmpty ? ['FCFA'] : currencies,
      extendedFields: _style == InvoiceStyle.modern,
      bannerLines: _lines(_banner),
      detailLines: _lines(_details),
      footerLines: _lines(_footer),
      bankLines: _bankLines(),
    );
  }

  List<String> _lines(TextEditingController controller) => controller.text
      .split('\n')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  List<(String, String)> _bankLines() {
    final bank = <(String, String)>[];
    for (final value in _bank.text.split('\n')) {
      final line = value.trim();
      if (line.isEmpty) continue;
      final i = line.indexOf(' : ');
      final j = i < 0 ? line.indexOf(': ') : i;
      if (j <= 0) {
        bank.add(('Compte', line));
      } else {
        bank.add((line.substring(0, j).trim(), line.substring(j + 1).trim()));
      }
    }
    return bank;
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_name.text.trim().isEmpty) {
      return _toast('Le nom de l’entreprise ne peut pas être vide.');
    }
    setState(() => _busy = true);
    final c = _collect();
    await ProfileStore.save(c);
    if (!mounted) return;
    setState(() {
      _current = c;
      _busy = false;
      _isNew = false;
    });
    await _refreshCompanies();
    widget.onChanged();
    _toast('Entreprise ${c.name} enregistrée.');
  }

  Future<void> _pickImage(String kind) async {
    if (kIsWeb) {
      return _toast(
          'Le choix d\'image depuis la galerie est disponible sur l\'application mobile.');
    }
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 88,
      );
      if (x == null) return;
      final path =
          await ProfileStore.copyImageToAppDir(x.path, _current.id, kind);
      setState(() {
        _current = switch (kind) {
          'logo' => _current.copyWith(logoAsset: path),
          'signature' => _current.copyWith(signatureAsset: path),
          _ => _current.copyWith(stampAsset: path),
        };
      });
      if (!_isNew) {
        final company = _collect();
        await ProfileStore.save(company);
        if (mounted) setState(() => _current = company);
      }
      widget.onChanged();
      _toast(kind == 'logo'
          ? 'Nouveau logo enregistré.'
          : kind == 'signature'
              ? 'Nouvelle signature enregistrée.'
              : 'Nouveau cachet enregistré.');
    } catch (e) {
      _toast('Impossible de choisir l\'image : $e');
    }
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser le profil ?'),
        content: Text(
            'Les informations de ${_current.name} reviendront aux valeurs par défaut '
            '(logo, nom, coordonnées).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Réinitialiser')),
        ],
      ),
    );
    if (ok != true) return;
    await ProfileStore.reset(_current.id);
    final fresh = await ProfileStore.company(_current.id);
    setState(() {
      _current = fresh;
      _loadFields();
    });
    widget.onChanged();
    _toast('Profil réinitialisé.');
  }

  void _newCompany() {
    final draft = Company.custom(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
    );
    setState(() {
      _current = draft;
      _isNew = true;
      _loadFields();
    });
  }

  Future<void> _deleteCompany() async {
    final invoiceCount = await InvoiceStore.countForCompany(_current.id);
    if (!mounted) return;
    final message = invoiceCount == 0
        ? 'Supprimer définitivement ${_current.name} ?'
        : 'Supprimer ${_current.name} et ses $invoiceCount factures associées ?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l’entreprise ?'),
        content: Text(message),
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
    if (confirmed != true) return;
    await ProfileStore.delete(_current.id);
    final companies = await ProfileStore.companies();
    if (!mounted) return;
    setState(() {
      _companies = companies;
      _current = companies.isEmpty
          ? Company.custom(
              id: DateTime.now().microsecondsSinceEpoch.toString(), name: '')
          : companies.first;
      _isNew = companies.isEmpty;
      _loadFields();
    });
    widget.onChanged();
  }

  Future<void> _logout() async {
    await AccountStore.logout();
    if (!mounted) return;
    widget.onLogout?.call();
    Navigator.of(context).pop(true);
  }

  Widget _field(String label, TextEditingController c,
          {int maxLines = 1, String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  Widget _imageCard({
    required String title,
    required String subtitle,
    required String? path,
    required VoidCallback onPick,
  }) {
    final isAsset = path != null && path.startsWith('assets/');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(children: [
        Container(
          width: 62,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: path == null
              ? const Icon(Icons.image_outlined,
                  size: 30, color: Color(0xFF0878CF))
              : (isAsset
                  ? Image.asset(path, fit: BoxFit.contain)
                  : Image.file(File(path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          size: 30,
                          color: Color(0xFF0878CF)))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF102B50))),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF697789))),
          ]),
        ),
        IconButton(
          tooltip: 'Choisir une image',
          icon: const Icon(Icons.photo_library_outlined,
              color: Color(0xFF0878CF)),
          onPressed: onPick,
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_current.color);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(
            _isNew ? 'Configurer mon entreprise' : 'Mon profil entreprise'),
        actions: [
          IconButton(
            tooltip: 'Ajouter une entreprise',
            icon: const Icon(Icons.add_business_outlined),
            onPressed: _newCompany,
          ),
          if (!_isNew)
            IconButton(
              tooltip: 'Supprimer cette entreprise',
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteCompany,
            ),
          if (!_isNew && kCompanies.any((company) => company.id == _current.id))
            IconButton(
              tooltip: 'Réinitialiser ce profil',
              icon: const Icon(Icons.restart_alt),
              onPressed: _reset,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_companies.isNotEmpty)
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0))),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  initialValue:
                      _companies.any((company) => company.id == _current.id)
                          ? _current.id
                          : null,
                  decoration:
                      const InputDecoration(labelText: 'Entreprise à modifier'),
                  items: [
                    for (final c in _companies)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) async {
                    if (v == null || v == _current.id) return;
                    final c = await ProfileStore.company(v);
                    setState(() {
                      _current = c;
                      _isNew = false;
                      _loadFields();
                    });
                  },
                ),
              ),
            ),
          const SizedBox(height: 6),
          _imageCard(
            title: 'Logo',
            subtitle: 'Apparaît sur l\'accueil et sur le PDF de la facture.',
            path: _current.logoAsset,
            onPick: () => _pickImage('logo'),
          ),
          _imageCard(
            title: 'Tampon / signature',
            subtitle: 'Cachet apposé en bas de la facture (facultatif).',
            path: _current.stampAsset,
            onPick: () => _pickImage('tampon'),
          ),
          _imageCard(
            title: 'Signature',
            subtitle: 'Image de signature indépendante, facultative.',
            path: _current.signatureAsset,
            onPick: () => _pickImage('signature'),
          ),
          _card('Identité de l\'entreprise', [
            _field('Nom de l’entreprise', _name),
            _field('Nom affiché sur la facture', _displayName),
            _field('Activité / sous-titre', _subtitle),
            _field('Libellé fiscal selon le pays', _taxIdLabel,
                hint: 'Ex. : NINEA'),
            _field('NINEA ou identifiant fiscal', _taxId),
            _field('RCCM (si applicable)', _rccm),
            _field('Adresse', _address, maxLines: 2),
            _field('Téléphone', _phone),
            _field('E-mail professionnel', _email),
            _field('Devises (séparées par des virgules)', _currencies,
                hint: 'FCFA, EUR, USD'),
            _field('Informations de facturation', _invoiceTerms, maxLines: 3),
            DropdownButtonFormField<InvoiceStyle>(
              initialValue: _style,
              decoration: const InputDecoration(labelText: 'Modèle de facture'),
              items: const [
                DropdownMenuItem(
                    value: InvoiceStyle.modern, child: Text('Moderne')),
                DropdownMenuItem(
                    value: InvoiceStyle.classic, child: Text('Classique')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _style = value);
              },
            ),
          ]),
          _card('En-tête de la facture', [
            _field('Lignes d\'activité (une par ligne)', _banner,
                maxLines: 4, hint: 'Ex. : FROID ELECTRO MECANICIEN'),
          ]),
          _card('Détails légaux et contact', [
            _field('Détails (une ligne par information)', _details,
                maxLines: 4, hint: 'NINEA : ...\nRCCM : ...\nTél. : ...'),
          ]),
          _card('Coordonnées bancaires', [
            _field('Comptes (format « Label : valeur », une ligne par compte)',
                _bank,
                maxLines: 4, hint: 'Compte bancaire : k0011 / ...'),
          ]),
          _card('Pied de page', [
            _field('Lignes du pied de page', _footer,
                maxLines: 4, hint: 'Adresse, téléphone, e-mail…'),
          ]),
          const SizedBox(height: 6),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _busy ? null : _save,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('Enregistrer le profil'),
          ),
          const SizedBox(height: 16),
          _accountCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
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

  Widget _accountCard() {
    return FutureBuilder<Account?>(
      future: AccountStore.current(),
      builder: (ctx, snap) {
        final acc = snap.data;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.account_circle_outlined,
                  color: Color(0xFF0878CF)),
              const SizedBox(width: 8),
              const Text('Mon compte',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFF102B50))),
            ]),
            const SizedBox(height: 8),
            Text('Nom : ${acc?.name ?? '—'}',
                style: const TextStyle(fontSize: 13)),
            Text('Contact : ${acc?.contact ?? '—'}',
                style: const TextStyle(fontSize: 13)),
            if (acc != null && acc.createdAt.isNotEmpty)
              Text(
                  'Compte créé le ${dateLabel(toIso(DateTime.tryParse(acc.createdAt) ?? DateTime.now()))}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF697789))),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Se déconnecter'),
            ),
          ]),
        );
      },
    );
  }
}

/// Petit logo réutilisable dans les listes.
Widget companyAvatar(Company c, {double radius = 24}) =>
    CompanyLogo(company: c, radius: radius);
