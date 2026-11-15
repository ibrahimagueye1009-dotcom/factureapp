import 'dart:io';
import 'dart:typed_data';

/// Lit une image depuis un chemin de fichier local (Android / desktop).
Future<Uint8List?> loadImageBytes(String path) async {
  final f = File(path);
  if (!await f.exists()) return null;
  return f.readAsBytes();
}

bool get canReadLocalFiles => true;
