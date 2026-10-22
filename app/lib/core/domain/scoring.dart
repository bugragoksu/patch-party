/// FR-11, mirrored from the server so the request card can preview the bonus.
class Points {
  const new({required this.base, required this.bonus});

  final int base;
  final int bonus;

  int get total => base + bonus;
}

Points pointsFor(List<String> a, List<String> b) {
  final shared = a.any(b.contains);
  return Points(base: 10, bonus: shared ? 0 : 5);
}
