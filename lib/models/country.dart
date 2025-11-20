class Country {
  final String code;       // ISO code used to match SVG path id, e.g. "IN", "US"
  final String name;
  final String capital;
  final String flagAsset;
  final double utcOffset;  // support fractional offsets like 5.5
  Country({
    required this.code,
    required this.name,
    required this.capital,
    required this.flagAsset,
    required this.utcOffset,
  });
}
