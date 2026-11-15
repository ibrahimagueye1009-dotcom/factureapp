import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../companies.dart';
import 'account.dart';
import 'store.dart';

/// Surcharge locale des informations entreprise : nom, activité,
/// logo, tampon, coordonnées bancaires, pied de page, etc.
/// Les valeurs par défaut restent celles de `companies.dart`.
class ProfileStore {
  static const _key = 'company_profiles_v1';
  static const _companiesPrefix = 'companies_v2_';
  static const _activePrefix = 'active_company_v2_';

  static String _companiesKey(String accountId) =>
      '$_companiesPrefix$accountId';

  static String _activeKey(String accountId) => '$_activePrefix$accountId';

  static Future<void> _ensureLegacyMigration() async {
    final account = await AccountStore.current();
    if (account == null || !account.isLegacy) return;
    final p = await SharedPreferences.getInstance();
    final key = _companiesKey(account.id);
    if (p.getString(key) != null) return;

    Map<String, dynamic> overrides = {};
    final raw = p.getString(_key);
    if (raw != null) {
      try {
        overrides = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    final migrated = [
      for (final company in kCompanies)
        _applyLegacyOverride(company, overrides[company.id]).toJson(),
    ];
    await p.setString(key, jsonEncode(migrated));
    await p.setString(_activeKey(account.id), kCompanies.first.id);
  }

  static Company _applyLegacyOverride(Company base, dynamic raw) {
    if (raw == null) return base;
    final data = Map<String, dynamic>.from(raw as Map);
    String? stringValue(String key) => data[key]?.toString().trim();
    List<String>? lines(String key) {
      final values = data[key] as List?;
      return values?.map((value) => value.toString()).toList();
    }

    List<(String, String)>? bankLines() {
      final values = data['bankLines'] as List?;
      if (values == null) return null;
      return values.map((entry) {
        final line = Map<String, dynamic>.from(entry as Map);
        return (line['k'].toString(), line['v'].toString());
      }).toList();
    }

    return base.copyWith(
      displayName: stringValue('displayName'),
      subtitle: stringValue('subtitle'),
      bannerLines: lines('bannerLines'),
      detailLines: lines('detailLines'),
      footerLines: lines('footerLines'),
      bankLines: bankLines(),
      logoAsset: stringValue('logoPath'),
      stampAsset: stringValue('stampPath'),
    );
  }

  static Future<List<Company>> _readAll() async {
    await _ensureLegacyMigration();
    final p = await SharedPreferences.getInstance();
    final accountId = await AccountStore.scopeId();
    final raw = p.getString(_companiesKey(accountId));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((value) =>
              Company.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeAll(List<Company> companies) async {
    final p = await SharedPreferences.getInstance();
    final accountId = await AccountStore.scopeId();
    await p.setString(
      _companiesKey(accountId),
      jsonEncode(companies.map((company) => company.toJson()).toList()),
    );
  }

  static Future<List<Company>> companies() => _readAll();

  static Future<Company> company(String id) async {
    final all = await _readAll();
    return all.firstWhere((company) => company.id == id,
        orElse: () => companyById(id));
  }

  static Future<Company> save(Company current) async {
    final all = await _readAll();
    final index = all.indexWhere((company) => company.id == current.id);
    if (index < 0) {
      all.add(current);
    } else {
      all[index] = current;
    }
    await _writeAll(all);
    final accountId = await AccountStore.scopeId();
    final p = await SharedPreferences.getInstance();
    if (p.getString(_activeKey(accountId)) == null) {
      await p.setString(_activeKey(accountId), current.id);
    }
    return current;
  }

  static Future<void> setActive(String companyId) async {
    final all = await _readAll();
    if (!all.any((company) => company.id == companyId)) return;
    final accountId = await AccountStore.scopeId();
    final p = await SharedPreferences.getInstance();
    await p.setString(_activeKey(accountId), companyId);
  }

  static Future<String?> activeId() async {
    final all = await _readAll();
    if (all.isEmpty) return null;
    final accountId = await AccountStore.scopeId();
    final p = await SharedPreferences.getInstance();
    final selected = p.getString(_activeKey(accountId));
    return all.any((company) => company.id == selected)
        ? selected
        : all.first.id;
  }

  static Future<void> delete(String companyId) async {
    final all = await _readAll();
    if (!all.any((company) => company.id == companyId)) return;
    await InvoiceStore.deleteForCompany(companyId);
    all.removeWhere((company) => company.id == companyId);
    await _writeAll(all);
    final accountId = await AccountStore.scopeId();
    final p = await SharedPreferences.getInstance();
    if (p.getString(_activeKey(accountId)) == companyId) {
      if (all.isEmpty) {
        await p.remove(_activeKey(accountId));
      } else {
        await p.setString(_activeKey(accountId), all.first.id);
      }
    }
  }

  /// Réinitialise une entreprise sur ses valeurs par défaut.
  static Future<void> reset(String companyId) async {
    final base = kCompanies.where((company) => company.id == companyId);
    if (base.isEmpty) {
      await delete(companyId);
      return;
    }
    await save(base.first);
  }

  /// Copie une image choisie par l'utilisateur dans le dossier
  /// de l'application et renvoie le chemin persistant.
  static Future<String> copyImageToAppDir(
      String pickedPath, String companyId, String kind) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/profile_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    final accountId = await AccountStore.scopeId();
    final ext = pickedPath.contains('.')
        ? pickedPath.substring(pickedPath.lastIndexOf('.'))
        : '.jpg';
    final dest = File('${dir.path}/${accountId}_${companyId}_$kind$ext');
    await File(pickedPath).copy(dest.path);
    return dest.path;
  }
}
