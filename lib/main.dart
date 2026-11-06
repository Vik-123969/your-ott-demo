import 'package:flutter/material.dart';

void main() => runApp(const YourOttApp());

const bg = Color(0xFF090B12);
const panel = Color(0xFF171B29);
const accent = Color(0xFF8B6CFF);

class YourOttApp extends StatelessWidget {
  const YourOttApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Your OTT',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      appBarTheme: const AppBarTheme(backgroundColor: bg, elevation: 0),
    ),
    home: const HomePage(),
  );
}

class Film {
  final String title, genre, year, emoji, language, type, synopsis;
  final Color color;
  const Film(this.title, this.genre, this.year, this.emoji, this.color,
      this.language, this.type, this.synopsis);
}

const films = [
  Film('The Last Horizon','Adventure • Sci-Fi','2026','🚀',Color(0xFF343B70),'English','Movie','A deep-space crew discovers a signal beyond the edge of the known galaxy.'),
  Film('Midnight Run','Thriller • Action','2025','🌃',Color(0xFF653D59),'Hindi','Movie','One night, one city and a race against an unseen enemy.'),
  Film('Monsoon Stories','Drama • Romance','2026','🌧️',Color(0xFF285B59),'Bengali','Series','Three families find their lives connected during one unforgettable monsoon.'),
  Film('The Hidden Kingdom','Fantasy • Adventure','2025','🏰',Color(0xFF68502D),'Tamil','Movie','A young explorer follows an ancient map to a forgotten kingdom.'),
  Film('Beyond The Stars','Sci-Fi • Mystery','2024','🌌',Color(0xFF3A4F79),'Telugu','Series','A mysterious event changes the lives of a small coastal town.'),
  Film('City Of Dreams','Drama','2026','🌆',Color(0xFF744B35),'Marathi','Movie','An aspiring artist searches for a place in a city that never sleeps.'),
  Film('Nilaavu','Family • Drama','2025','🌙',Color(0xFF315A69),'Malayalam','Movie','A heartfelt story about home, memory and second chances.'),
  Film('Rangbaaz Gully','Crime • Drama','2026','🎭',Color(0xFF6A3E38),'Bhojpuri','Series','A neighbourhood storyteller gets pulled into a complicated local mystery.'),
  Film('Northbound','Adventure • Drama','2024','🏔️',Color(0xFF416052),'Punjabi','Movie','Two friends take an unexpected journey across the mountains.'),
  Film('The Last Letter','Romance • Mystery','2025','💌',Color(0xFF74465F),'Kannada','Series','A letter arrives every year, revealing a family secret one page at a time.'),
  Film('Blue Lantern','Mystery • Thriller','2026','🏮',Color(0xFF3A5270),'Japanese','Movie','A quiet seaside town hides a story that was never meant to be told.'),
  Film('Golden Hour','Comedy • Drama','2025','🌅',Color(0xFF795A32),'Korean','Series','Four strangers share a tiny cafe and change each other’s plans.')
];

const languages = ['All Languages','Hindi','English','Tamil','Telugu','Malayalam','Kannada','Bengali','Marathi','Punjabi','Bhojpuri','Japanese','Korean'];
const genres = ['All Genres','Action','Adventure','Comedy','Crime','Drama','Family','Fantasy','Mystery','Romance','Sci-Fi','Thriller'];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  String query = '';
  String language = 'All Languages';
  String genre = 'All Genres';
  final Set<String> saved = {};

  List<Film> get filtered => films.where((f) {
    final q = query.trim().toLowerCase();
    final matchesQuery = q.isEmpty || '${f.title} ${f.genre} ${f.language}'.toLowerCase().contains(q);
    final matchesLanguage = language == 'All Languages' || f.language == language;
    final matchesGenre = genre == 'All Genres' || f.genre.toLowerCase().contains(genre.toLowerCase());
    return matchesQuery && matchesLanguage && matchesGenre;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final items = filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOUR OTT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
        actions: [IconButton(onPressed: () => setState(() => tab = 3), icon: const Icon(Icons.bookmark_border)), const SizedBox(width: 8)],
      ),
      body: IndexedStack(index: tab, children: [
        _home(items),
        _catalog(items, 'Movies', 'Movie'),
        _catalog(items, 'Series', 'Series'),
        _myList(),
        _profile(),
      ]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        indicatorColor: accent.withValues(alpha: .25),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.movie_outlined), label: 'Movies'),
          NavigationDestination(icon: Icon(Icons.live_tv_outlined), label: 'Series'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), label: 'My List'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _searchBox() => TextField(
    onChanged: (v) => setState(() => query = v),
    decoration: InputDecoration(
      hintText: 'Search titles, genres or languages',
      prefixIcon: const Icon(Icons.search),
      filled: true, fillColor: panel,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
  );

  Widget _filters() => Column(children: [
    Row(children: [
      Expanded(child: _dropdown(language, languages, (v) => setState(() => language = v))),
      const SizedBox(width: 10),
      Expanded(child: _dropdown(genre, genres, (v) => setState(() => genre = v))),
    ]),
    const SizedBox(height: 12),
    SizedBox(height: 38, child: ListView(
      scrollDirection: Axis.horizontal,
      children: ['All','Hindi','English','Tamil','Telugu','Malayalam','Bengali','Punjabi','Bhojpuri'].map((v) {
        final selected = v == 'All' ? language == 'All Languages' : language == v;
        return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
          label: Text(v), selected: selected,
          onSelected: (_) => setState(() => language = v == 'All' ? 'All Languages' : v),
          selectedColor: accent.withValues(alpha: .35),
        ));
      }).toList(),
    )),
  ]);

  Widget _dropdown(String value, List<String> options, ValueChanged<String> onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: value, isExpanded: true, dropdownColor: panel,
      items: options.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    )),
  );

  Widget _home(List<Film> items) {
    final movies = items.where((f) => f.type == 'Movie').toList();
    final series = items.where((f) => f.type == 'Series').toList();
    return ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 24), children: [
      Container(
        height: 210, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xFF4934A5), Color(0xFF171D38)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text('ONE APP.\nMANY WORLDS.', style: TextStyle(fontSize: 27, height: 1.05, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Movies and series across languages', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => _open(films[0]), icon: const Icon(Icons.play_arrow), label: const Text('Explore now')),
        ]),
      ),
      const SizedBox(height: 18),
      _searchBox(),
      const SizedBox(height: 16),
      _filters(),
      const SizedBox(height: 22),
      _heading('Trending Now'),
      _horizontal(items),
      const SizedBox(height: 22),
      _heading('Movies'),
      _horizontal(movies),
      const SizedBox(height: 22),
      _heading('Web Series'),
      _horizontal(series),
      const SizedBox(height: 22),
      _heading('Explore All Titles'),
      if (items.isEmpty) _empty('No titles match these filters. Try another language or genre.'),
      ...items.map(_tile),
      const SizedBox(height: 10),
      const Text('Demo catalogue • Fictional sample titles', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11)),
    ]);
  }

  Widget _catalog(List<Film> items, String label, String type) {
    final list = items.where((f) => f.type == type).toList();
    return ListView(padding: const EdgeInsets.all(18), children: [
      Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(type == 'Movie' ? 'Explore films from around the world' : 'Discover stories in every language', style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 16),
      _searchBox(),
      const SizedBox(height: 14),
      _filters(),
      const SizedBox(height: 16),
      if (list.isEmpty) _empty('No $label found for the selected filters.'),
      ...list.map(_tile),
    ]);
  }

  Widget _myList() => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('My List', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    if (saved.isEmpty) _empty('Save movies and series to find them here.'),
    ...films.where((f) => saved.contains(f.title)).map(_tile),
  ]);

  Widget _profile() => const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    CircleAvatar(radius: 38, backgroundColor: panel, child: Icon(Icons.person, size: 42)),
    SizedBox(height: 14), Text('Welcome to Your OTT', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
    SizedBox(height: 6), Text('Demo profile • Account setup coming later', style: TextStyle(color: Colors.white60)),
  ]));

  Widget _empty(String message) => Padding(padding: const EdgeInsets.symmetric(vertical: 28), child: Center(child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60))));

  Widget _heading(String text) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));

  Widget _horizontal(List<Film> items) => SizedBox(
    height: 172,
    child: items.isEmpty ? const Center(child: Text('No titles yet', style: TextStyle(color: Colors.white54))) :
    ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) => SizedBox(width: 132, child: _poster(items[i])),
    ),
  );

  Widget _tile(Film f) => Card(
    color: panel, margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(contentPadding: const EdgeInsets.all(8),
      leading: _art(f, 58, 64),
      title: Text(f.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${f.language} • ${f.type} • ${f.year}\n${f.genre}', style: const TextStyle(color: Colors.white60), maxLines: 2),
      isThreeLine: true,
      trailing: IconButton(icon: Icon(saved.contains(f.title) ? Icons.bookmark : Icons.bookmark_add_outlined, color: accent),
        onPressed: () => setState(() { saved.contains(f.title) ? saved.remove(f.title) : saved.add(f.title); })),
      onTap: () => _open(f),
    ),
  );

  Widget _poster(Film f) => GestureDetector(onTap: () => _open(f), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: _art(f, double.infinity, double.infinity))),
    const SizedBox(height: 6),
    Text(f.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
    Text('${f.language} • ${f.type}', maxLines: 1, style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]));

  Widget _art(Film f, double w, double h) => Container(width: w, height: h, alignment: Alignment.center,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(colors: [f.color, f.color.withValues(alpha: .45)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Text(f.emoji, style: const TextStyle(fontSize: 34)));

  void _open(Film f) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(
    film: f, saved: saved.contains(f.title),
    onSave: () => setState(() { saved.contains(f.title) ? saved.remove(f.title) : saved.add(f.title); }),
  )));
}

class DetailPage extends StatelessWidget {
  final Film film;
  final bool saved;
  final VoidCallback onSave;
  const DetailPage({super.key, required this.film, required this.saved, required this.onSave});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Title Details')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(height: 230, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [film.color, bg])),
        child: Center(child: Text(film.emoji, style: const TextStyle(fontSize: 80)))),
      const SizedBox(height: 20),
      Text(film.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('${film.language} • ${film.type} • ${film.year}', style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 8),
      Text(film.genre, style: const TextStyle(color: accent)),
      const SizedBox(height: 18),
      Text(film.synopsis, style: const TextStyle(height: 1.5)),
      const SizedBox(height: 12),
      const Text('Demo catalogue • Fictional sample title', style: TextStyle(color: Colors.white38, fontSize: 12)),
      const SizedBox(height: 22),
      FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerPage())),
        icon: const Icon(Icons.play_arrow), label: const Text('Play Demo')),
      OutlinedButton.icon(onPressed: onSave, icon: Icon(saved ? Icons.bookmark : Icons.bookmark_add_outlined), label: Text(saved ? 'Saved to My List' : 'Add to My List')),
    ]));
}

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Your OTT Player')),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
      Icon(Icons.ondemand_video, size: 82, color: accent),
      SizedBox(height: 16), Text('Demo Player', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      SizedBox(height: 8), Text('Licensed video streaming will be connected later.', style: TextStyle(color: Colors.white60)),
    ])));
}
