enum InvoiceStyle { classic, modern }

class Company {
  final String id;
  final String name;
  final String displayName;
  final String subtitle;
  final String prefix;
  final InvoiceStyle style;
  final int color;
  final String? logoAsset;
  final String? stampAsset;
  final String? signatureAsset;
  final String taxIdLabel;
  final String taxId;
  final String rccm;
  final String address;
  final String phone;
  final String email;
  final String invoiceTerms;
  final List<String> bannerLines;
  final List<(String, String)> bankLines;
  final List<String> footerLines;
  final List<String> detailLines;
  final bool extendedFields;
  final List<String> currencies;

  const Company({
    required this.id,
    required this.name,
    required this.displayName,
    required this.subtitle,
    required this.prefix,
    required this.style,
    required this.color,
    this.logoAsset,
    this.stampAsset,
    this.signatureAsset,
    this.taxIdLabel = 'NINEA',
    this.taxId = '',
    this.rccm = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.invoiceTerms = '',
    this.bannerLines = const [],
    this.bankLines = const [],
    this.footerLines = const [],
    this.detailLines = const [],
    this.extendedFields = false,
    this.currencies = const ['FCFA'],
  });

  factory Company.custom({required String id, required String name}) {
    final prefix = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(4)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Company(
      id: id,
      name: name.trim(),
      displayName: name.trim(),
      subtitle: '',
      prefix: prefix.isEmpty ? 'FAC' : prefix,
      style: InvoiceStyle.modern,
      color: 0xFF0878CF,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'displayName': displayName,
        'subtitle': subtitle,
        'prefix': prefix,
        'style': style.name,
        'color': color,
        'logoAsset': logoAsset,
        'stampAsset': stampAsset,
        'signatureAsset': signatureAsset,
        'taxIdLabel': taxIdLabel,
        'taxId': taxId,
        'rccm': rccm,
        'address': address,
        'phone': phone,
        'email': email,
        'invoiceTerms': invoiceTerms,
        'bannerLines': bannerLines,
        'detailLines': detailLines,
        'footerLines': footerLines,
        'bankLines': [
          for (final line in bankLines) {'k': line.$1, 'v': line.$2},
        ],
        'extendedFields': extendedFields,
        'currencies': currencies,
      };

  factory Company.fromJson(Map<String, dynamic> json) {
    final styleName = json['style']?.toString();
    final bankLines = (json['bankLines'] as List? ?? []).map((entry) {
      final line = Map<String, dynamic>.from(entry as Map);
      return (line['k']?.toString() ?? '', line['v']?.toString() ?? '');
    }).toList();
    List<String> strings(String key) =>
        (json[key] as List? ?? []).map((value) => value.toString()).toList();

    return Company(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayName:
          json['displayName']?.toString() ?? json['name']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      prefix: json['prefix']?.toString() ?? 'FAC',
      style: styleName == InvoiceStyle.classic.name
          ? InvoiceStyle.classic
          : InvoiceStyle.modern,
      color: (json['color'] as num?)?.toInt() ?? 0xFF0878CF,
      logoAsset: json['logoAsset']?.toString(),
      stampAsset: json['stampAsset']?.toString(),
      signatureAsset: json['signatureAsset']?.toString(),
      taxIdLabel: json['taxIdLabel']?.toString() ?? 'NINEA',
      taxId: json['taxId']?.toString() ?? '',
      rccm: json['rccm']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      invoiceTerms: json['invoiceTerms']?.toString() ?? '',
      bannerLines: strings('bannerLines'),
      detailLines: strings('detailLines'),
      footerLines: strings('footerLines'),
      bankLines: bankLines,
      extendedFields: json['extendedFields'] as bool? ?? false,
      currencies: strings('currencies').isEmpty
          ? const ['FCFA']
          : strings('currencies'),
    );
  }

  /// Copie en ne remplaçant que les valeurs fournies.
  Company copyWith({
    String? name,
    String? displayName,
    String? subtitle,
    String? prefix,
    InvoiceStyle? style,
    int? color,
    String? taxIdLabel,
    String? taxId,
    String? rccm,
    String? address,
    String? phone,
    String? email,
    String? invoiceTerms,
    List<String>? bannerLines,
    List<String>? detailLines,
    List<String>? footerLines,
    List<(String, String)>? bankLines,
    String? logoAsset,
    bool clearLogoAsset = false,
    String? stampAsset,
    bool clearStampAsset = false,
    String? signatureAsset,
    bool clearSignatureAsset = false,
    List<String>? currencies,
    bool? extendedFields,
  }) =>
      Company(
        id: id,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        subtitle: subtitle ?? this.subtitle,
        prefix: prefix ?? this.prefix,
        style: style ?? this.style,
        color: color ?? this.color,
        logoAsset: clearLogoAsset ? null : logoAsset ?? this.logoAsset,
        stampAsset: clearStampAsset ? null : stampAsset ?? this.stampAsset,
        signatureAsset:
            clearSignatureAsset ? null : signatureAsset ?? this.signatureAsset,
        taxIdLabel: taxIdLabel ?? this.taxIdLabel,
        taxId: taxId ?? this.taxId,
        rccm: rccm ?? this.rccm,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        invoiceTerms: invoiceTerms ?? this.invoiceTerms,
        bannerLines: bannerLines ?? this.bannerLines,
        bankLines: bankLines ?? this.bankLines,
        footerLines: footerLines ?? this.footerLines,
        detailLines: detailLines ?? this.detailLines,
        extendedFields: extendedFields ?? this.extendedFields,
        currencies: currencies ?? this.currencies,
      );
}

const saerDrame = Company(
  id: 'saer',
  name: 'SAER DRAME',
  displayName: 'SAER DRAME Entreprise',
  subtitle: 'Froid Électro Mécanicien - Frigoriste',
  prefix: 'SD',
  style: InvoiceStyle.classic,
  color: 0xFF1E3A8A,
  logoAsset: 'assets/images/logo.jpg',
  stampAsset: 'assets/images/tampon.png',
  bannerLines: [
    'FROID ELECTRO MECANICIEN',
    'MONTEUR DEPANNEUR FRIGORISTE',
    "SPECIALISTE EN LIQUEFACTION DES GAZ DE L'AIR",
  ],
  bankLines: [
    (
      'Compte bancaire',
      'k0011 / 01018 / 003006476929 / 14 / Société générale de banques au Sénégal, Agence Centenaire Dakar'
    ),
    (
      'Compte ECOBANK',
      'SN094 / 01001 / 101285569001 / 95 / Km5 Avenue Cheikh Anta Diop Dakar'
    ),
  ],
  footerLines: [
    'Rue 14 prolonger coté de la Dunya et RDV',
    'N.I.N.E.A : 005554870 / RCCM 14506',
    'tel. +221 33 876 38 65 / 77 643 20 41',
    'Mail: dramesaer@yahoo.fr',
  ],
);

const dte = Company(
  id: 'dte',
  name: 'D-T-E',
  displayName: 'D-T-E — DRAME TECHNOLOGIQUE ET ÉLECTRONIQUE',
  subtitle: 'Drame Technologique et Électronique',
  prefix: 'DTE',
  style: InvoiceStyle.modern,
  color: 0xFF0878CF,
  logoAsset: 'assets/images/dte_logo.png',
  bannerLines: ['Toute fourniture électronique, mécanique et froid industriel'],
  detailLines: [
    'NINEA : 013210018',
    'RCCM : SN.DKR.2026.A.40988',
    'Tél. : 78 584 15 88 / 77 988 49 16',
  ],
  footerLines: [
    'D-T-E · Drame Technologique et Électronique',
    'Toute fourniture électronique, mécanique et froid industriel',
  ],
  extendedFields: true,
  currencies: ['FCFA', '€', '\$'],
);

const kCompanies = [saerDrame, dte];

Company companyById(String id) =>
    kCompanies.firstWhere((c) => c.id == id, orElse: () => dte);
