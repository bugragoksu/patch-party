import 'package:flutter/material.dart';

class PlayerRoot extends StatelessWidget {
  const new({super.key, this.joinCode, this.scannedPayload});

  final String? joinCode;
  final String? scannedPayload;

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox());
}
