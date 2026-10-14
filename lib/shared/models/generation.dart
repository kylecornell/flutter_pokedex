/// One Pokédex generation: National Dex number range and home region.
class Generation {
  const Generation({
    required this.first,
    required this.last,
    required this.region,
    required this.roman,
  });

  final int first;
  final int last;
  final String region;
  final String roman;

  /// `Gen III`
  String get label => 'Gen $roman';

  bool contains(int pokedexNumber) =>
      pokedexNumber >= first && pokedexNumber <= last;
}

const List<Generation> pokemonGenerations = [
  Generation(first: 1, last: 151, region: 'Kanto', roman: 'I'),
  Generation(first: 152, last: 251, region: 'Johto', roman: 'II'),
  Generation(first: 252, last: 386, region: 'Hoenn', roman: 'III'),
  Generation(first: 387, last: 493, region: 'Sinnoh', roman: 'IV'),
  Generation(first: 494, last: 649, region: 'Unova', roman: 'V'),
  Generation(first: 650, last: 721, region: 'Kalos', roman: 'VI'),
  Generation(first: 722, last: 809, region: 'Alola', roman: 'VII'),
  Generation(first: 810, last: 905, region: 'Galar', roman: 'VIII'),
  Generation(first: 906, last: 1025, region: 'Paldea', roman: 'IX'),
];

/// Index into [pokemonGenerations] for an API name like `generation-iii`.
/// Unknown names fall back to the first generation.
int generationIndexFromApiName(String? apiName) {
  final roman = apiName?.split('-').last.toUpperCase();
  final index = pokemonGenerations.indexWhere((g) => g.roman == roman);
  return index < 0 ? 0 : index;
}
