import 'package:flutter/material.dart';

import '../companies.dart';
import '../services/profile.dart';
import '../widgets/company_logo.dart';
import 'company_screen.dart';
import 'invoice_list.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const HomeScreen({super.key, this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _rev = 0;
  bool _setupOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialSetup());
  }

  Future<void> _openInitialSetup() async {
    if (_setupOpened) return;
    final companies = await ProfileStore.companies();
    if (!mounted || companies.isNotEmpty) return;
    _setupOpened = true;
    final draft = Company.custom(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          initialCompany: draft,
          isNew: true,
          onLogout: widget.onLogout,
          onChanged: () => setState(() => _rev++),
        ),
      ),
    );
    if (mounted) setState(() => _rev++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _tab == 0
            ? _Welcome(
                onRefresh: () => setState(() => _rev++),
                onLogout: widget.onLogout,
              )
            : Column(children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Toutes les factures',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF102B50))),
                  ),
                ),
                Expanded(child: InvoiceListView(key: ValueKey(_rev))),
              ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          _rev++;
        }),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Factures'),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback? onLogout;
  const _Welcome({required this.onRefresh, required this.onLogout});

  Future<(List<Company>, String?)> _loadCompanies() async {
    final companies = await ProfileStore.companies();
    return (companies, await ProfileStore.activeId());
  }

  Future<void> _openProfile(BuildContext context,
      {bool addCompany = false}) async {
    final companies = await ProfileStore.companies();
    final activeId = await ProfileStore.activeId();
    if (!context.mounted) return;
    final selected = addCompany || companies.isEmpty
        ? Company.custom(
            id: DateTime.now().microsecondsSinceEpoch.toString(), name: '')
        : companies.firstWhere(
            (company) => company.id == activeId,
            orElse: () => companies.first,
          );
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileScreen(
                  initialCompany: selected,
                  isNew: addCompany || companies.isEmpty,
                  onLogout: onLogout,
                  onChanged: onRefresh,
                )));
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(
            child: Icon(Icons.receipt_long, size: 40, color: Color(0xFF0878CF)),
          ),
          IconButton(
            tooltip: 'Mon profil entreprise',
            onPressed: () => _openProfile(context),
            icon: const Icon(Icons.business_center_outlined,
                color: Color(0xFF0878CF), size: 28),
          ),
        ]),
        const SizedBox(height: 10),
        const Text('Générateur de Factures',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102B50))),
        const SizedBox(height: 6),
        const Text('Sélectionnez l\'entreprise pour créer votre facture',
            style: TextStyle(color: Color(0xFF697789))),
        const SizedBox(height: 24),
        FutureBuilder<(List<Company>, String?)>(
          future: _loadCompanies(),
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final companies = snap.data?.$1 ?? [];
            final activeId = snap.data?.$2;
            final active = companies.isEmpty
                ? null
                : companies.firstWhere(
                    (company) => company.id == activeId,
                    orElse: () => companies.first,
                  );
            return Column(children: [
              if (active != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(children: [
                    CompanyLogo(company: active, radius: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Entreprise active',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF697789))),
                          Text(active.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF102B50))),
                          if (active.address.isNotEmpty ||
                              active.phone.isNotEmpty)
                            Text(
                              [active.address, active.phone]
                                  .where((value) => value.isNotEmpty)
                                  .join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF697789)),
                            ),
                        ],
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: active.id,
                        items: [
                          for (final company in companies)
                            DropdownMenuItem(
                                value: company.id,
                                child: Text(company.name,
                                    overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (id) async {
                          if (id == null) return;
                          await ProfileStore.setActive(id);
                          onRefresh();
                        },
                      ),
                    ),
                  ]),
                ),
              ],
              if (companies.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Configurez votre entreprise pour commencer.'),
                ),
              for (final c in companies) ...[
                _CompanyCard(
                  company: c,
                  isActive: c.id == active?.id,
                  onTap: () async {
                    await ProfileStore.setActive(c.id);
                    if (!context.mounted) return;
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CompanyScreen(company: c)));
                    onRefresh();
                  },
                ),
                const SizedBox(height: 14),
              ],
              OutlinedButton.icon(
                onPressed: () => _openProfile(context, addCompany: true),
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Ajouter une entreprise'),
              ),
            ]);
          },
        ),
      ],
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  final bool isActive;
  final VoidCallback onTap;
  const _CompanyCard(
      {required this.company, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(company.color);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.35), width: 2),
          ),
          child: Row(children: [
            CompanyLogo(company: company, radius: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        company.id == 'saer'
                            ? 'SAER DRAME Entreprise'
                            : company.name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF102B50))),
                    const SizedBox(height: 3),
                    Text(company.subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF697789))),
                  ]),
            ),
            Icon(isActive ? Icons.check_circle : Icons.chevron_right,
                color: color),
          ]),
        ),
      ),
    );
  }
}
