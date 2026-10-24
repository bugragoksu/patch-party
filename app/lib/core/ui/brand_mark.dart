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
