import 'dart:io';

import 'package:flutter/material.dart';

import '../companies.dart';

/// Logo de l'entreprise : soit l'asset par défaut, soit l'image
/// choisie par l'utilisateur (chemin de fichier).
class CompanyLogo extends StatelessWidget {
  final Company company;
  final double radius;
  final String? initials;
  const CompanyLogo(
      {super.key, required this.company, this.radius = 32, this.initials});

  ImageProvider? _provider() {
    final path = company.logoAsset;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final label = initials ??
        (company.id == 'saer' ? 'SD' : company.name.split('-').first.trim());
    final color = Color(company.color);
    final provider = _provider();
    if (provider == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color,
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: Image(
          image: provider,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: radius * 2,
            height: radius * 2,
            color: color,
            alignment: Alignment.center,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
