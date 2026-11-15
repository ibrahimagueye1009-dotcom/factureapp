import 'dart:typed_data';

/// Version Web : pas d'accès au système de fichiers.
Future<Uint8List?> loadImageBytes(String path) async => null;

bool get canReadLocalFiles => false;
