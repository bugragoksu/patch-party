import 'package:baglanti_agi/app/env.dart';
import 'package:flutter/material.dart';

/// The Patch Party mark: a stitched sticker patch with connected dots.
/// Source art lives in `web/brand/` (SVG); this is its PNG render.
class BrandMark extends StatelessWidget {
  const new({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset('assets/brand/mark.png', width: size, height: size),
  );
}

/// The organiser's logo (white, for the dark stage). Replace
/// `assets/brand/organizer.png` with your own and set APP_ORGANIZER_LOGO=true;
/// the GDG Adana example's source is `web/brand/organizer-example-gdg-adana.svg`.
class OrganizerLogo extends StatelessWidget {
  const new({super.key, this.height = 40});

  final double height;

  @override
  Widget build(BuildContext context) {
    if (!Env.organizerLogo) return const SizedBox.shrink();
    return Image.asset(
      'assets/brand/organizer.png',
      height: height,
      semanticLabel: Env.organizerName,
    );
  }
}
