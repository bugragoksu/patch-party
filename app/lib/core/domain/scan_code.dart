/// Client-side pre-check of a scanned or typed code (the server re-checks).
/// Mirrors parseScannedCode in functions/src/domain/rules.ts.
sealed class ScanInput {
  const new();

  static ScanInput? parse(String raw) {
    final input = raw.trim().toUpperCase();
    final qr = RegExp(r'(?:^|/C/)([A-Z2-9]{3})\.([0-9A-HJKMNP-TV-Z]{10})$')
        .firstMatch(input);
    if (qr != null) return QrScan(qr.group(1)!, qr.group(2)!);
    final manual = RegExp(r'^([A-Z2-9]{3})[\s-]*([0-9]{4})$').firstMatch(input);
    if (manual != null) return ManualCode(manual.group(1)!, manual.group(2)!);
    return null;
  }

  String get playerCode;

  /// What is sent to requestConnection.
  String get wire;
}

class QrScan extends ScanInput {
  const new(this.playerCode, this.token);
  @override
  final String playerCode;
  final String token;
  @override
  String get wire => '$playerCode.$token';
}

class ManualCode extends ScanInput {
  const new(this.playerCode, this.digits);
  @override
  final String playerCode;
  final String digits;
  @override
  String get wire => '$playerCode-$digits';
}
