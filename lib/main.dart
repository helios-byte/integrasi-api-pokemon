import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() => runApp(PokeApp());

class PokeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeAPI Demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: PokemonListPage(),
    );
  }
}

class PokemonListPage extends StatefulWidget {
  @override
  _PokemonListPageState createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage> {
  List<dynamic> pokemonList = [];
  bool isLoading = true;
  String searchQuery = '';
  List<String> recentlyViewed = [];
  int randomPokemonId = Random().nextInt(50) + 1;

  @override
  void initState() {
    super.initState();
    fetchPokemon();
  }

  Future<void> fetchPokemon() async {
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        pokemonList = data['results'];
        isLoading = false;
      });
    } else {
      throw Exception('Gagal memuat data Pokémon');
    }
  }

  String getImageUrl(int index) {
    final id = index + 1;
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = pokemonList.where((pokemon) {
      final name = pokemon['name'].toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Daftar Pokémon')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Cari Pokémon',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final url =
                        'https://pokeapi.co/api/v2/pokemon/$randomPokemonId';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PokemonDetailPage(apiUrl: url, name: 'Random'),
                      ),
                    );
                  },
                  child: Text('Lihat Pokémon Acak Hari Ini'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final pokemon = filteredList[index];
                      final id = pokemonList.indexOf(pokemon) + 1;
                      return Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Image.network(getImageUrl(id - 1)),
                          title:
                              Text(pokemon['name'].toString().toUpperCase()),
                          onTap: () {
                            setState(() {
                              recentlyViewed.add(pokemon['name']);
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PokemonDetailPage(
                                  apiUrl: pokemon['url'],
                                  name: pokemon['name'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (recentlyViewed.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Terakhir dilihat: ${recentlyViewed.join(', ')}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
    );
  }
}

// Fungsi menentukan kelangkaan berdasarkan base_experience
String getRarity(int baseExperience) {
  if (baseExperience < 100) return 'Common';
  if (baseExperience < 150) return 'Uncommon';
  if (baseExperience < 200) return 'Rare';
  return 'Legendary';
}

class PokemonDetailPage extends StatefulWidget {
  final String apiUrl;
  final String name;

  PokemonDetailPage({required this.apiUrl, required this.name});

  @override
  _PokemonDetailPageState createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage> {
  Map<String, dynamic>? pokemonData;
  bool isLoading = true;
  String rarity = '';

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    final response = await http.get(Uri.parse(widget.apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        pokemonData = data;
        rarity = getRarity(data['base_experience']);
        isLoading = false;
      });
    } else {
      throw Exception('Gagal memuat detail Pokémon');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name.toUpperCase()),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Image.network(pokemonData!['sprites']['front_default']),
                Text('Tinggi: ${pokemonData!['height']}'),
                Text('Berat: ${pokemonData!['weight']}'),
                Text(
                  'Tipe: ${pokemonData!['types'].map((t) => t['type']['name']).join(', ')}',
                ),
                Text(
                  'Kelangkaan: $rarity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rarity == 'Legendary'
                        ? Colors.amber[700]
                        : rarity == 'Rare'
                            ? Colors.deepPurple
                            : rarity == 'Uncommon'
                                ? Colors.green
                                : Colors.grey,
                  ),
                ),
              ],
            ),
    );
  }
}
