import 'package:flutter/material.dart';

void main() => runApp(const YourOttApp());

const bg = Color(0xFF090B12);
const panel = Color(0xFF171B29);
const accent = Color(0xFF7C5CFF);

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
  final String title, genre, year, emoji;
  final Color color;
  const Film(this.title, this.genre, this.year, this.emoji, this.color);
}

const films = [
  Film('The Last Horizon', 'Adventure • Sci-Fi', '2026', '🚀', Color(0xFF343B70)),
  Film('Midnight Run', 'Thriller • Action', '2025', '🌃', Color(0xFF653D59)),
  Film('Monsoon Stories', 'Drama • Romance', '2026', '🌧️', Color(0xFF285B59)),
  Film('The Hidden Kingdom', 'Fantasy • Adventure', '2025', '🏰', Color(0xFF68502D)),
  Film('Beyond The Stars', 'Sci-Fi • Mystery', '2024', '🌌', Color(0xFF3A4F79)),
  Film('City Of Dreams', 'Drama', '2026', '🌆', Color(0xFF744B35)),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  String query = '';
  final Set<String> saved = {};
  final pages = const ['Home', 'Movies', 'Series', 'My List', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final visible = films.where((f) =>
      f.title.toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOUR OTT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
        actions: [
          IconButton(onPressed: () => setState(() => tab = 3),
            icon: const Icon(Icons.bookmark_border)),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: tab, children: [
        _home(visible),
        _catalog(visible, 'Movies'),
        _catalog(visible, 'Series'),
        _myList(),
        _profile(),
      ]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        indicatorColor: accent.withOpacity(.25),
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

  Widget _home(List<Film> items) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
    children: [
      Container(
        height: 205, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xFF4934A5), Color(0xFF171D38)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text('YOUR NEXT\nFAVORITE STORY', style: TextStyle(fontSize: 25, height: 1.05, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Discover movies, series and more', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () => _open(films[0]), icon: const Icon(Icons.play_arrow), label: const Text('Explore now')),
        ]),
      ),
      const SizedBox(height: 22),
      TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: InputDecoration(
          hintText: 'Search movies and series',
          prefixIcon: const Icon(Icons.search),
          filled: true, fillColor: panel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 22),
      _heading('Trending Now'),
      _horizontal(items),
      const SizedBox(height: 22),
      _heading('Popular Picks'),
      ...items.map(_tile),
    ],
  );

  Widget _catalog(List<Film> items, String label) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(onChanged: (v) => setState(() => query = v),
        decoration: InputDecoration(hintText: 'Search $label', prefixIcon: const Icon(Icons.search), filled: true, fillColor: panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
      const SizedBox(height: 14),
      ...items.map(_tile),
    ],
  );

  Widget _myList() => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('My List', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    if (saved.isEmpty) const Text('Your saved titles will appear here.', style: TextStyle(color: Colors.white60)),
    ...films.where((f) => saved.contains(f.title)).map(_tile),
  ]);

  Widget _profile() => const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    CircleAvatar(radius: 38, backgroundColor: panel, child: Icon(Icons.person, size: 42)),
    SizedBox(height: 14), Text('Welcome to Your OTT', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
    SizedBox(height: 6), Text('Demo profile • Sign-in coming later', style: TextStyle(color: Colors.white60)),
  ]));

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  );

  Widget _horizontal(List<Film> items) => SizedBox(
    height: 164,
    child: ListView.separated(
      scrollDirection: Axis.horizontal, itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) => SizedBox(width: 132, child: _poster(items[i], compact: true)),
    ),
  );

  Widget _tile(Film f) => Card(
    color: panel, margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.all(8),
      leading: _art(f, 58, 64),
      title: Text(f.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${f.genre} • ${f.year}', style: const TextStyle(color: Colors.white60)),
      trailing: IconButton(
        icon: Icon(saved.contains(f.title) ? Icons.bookmark : Icons.bookmark_add_outlined, color: accent),
        onPressed: () => setState(() { saved.contains(f.title) ? saved.remove(f.title) : saved.add(f.title); }),
      ),
      onTap: () => _open(f),
    ),
  );

  Widget _poster(Film f, {bool compact = false}) => GestureDetector(
    onTap: () => _open(f),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: _art(f, double.infinity, double.infinity))),
      const SizedBox(height: 6),
      Text(f.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      if (!compact) Text(f.genre, maxLines: 1, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ]),
  );

  Widget _art(Film f, double w, double h) => Container(
    width: w, height: h, alignment: Alignment.center,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [f.color, f.color.withOpacity(.45)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Text(f.emoji, style: const TextStyle(fontSize: 34)),
  );

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Title Details')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(height: 230, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [film.color, bg])),
        child: Center(child: Text(film.emoji, style: const TextStyle(fontSize: 80)))),
      const SizedBox(height: 20),
      Text(film.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('${film.genre} • ${film.year}', style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 18),
      const Text('A demo title on Your OTT. Streaming content will be connected in a future version with properly licensed video sources.', style: TextStyle(height: 1.5)),
      const SizedBox(height: 22),
      FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerPage())),
        icon: const Icon(Icons.play_arrow), label: const Text('Play Demo')),
      OutlinedButton.icon(onPressed: onSave, icon: Icon(saved ? Icons.bookmark : Icons.bookmark_add_outlined), label: Text(saved ? 'Saved to My List' : 'Add to My List')),
    ]),
  );
}

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your OTT Player')),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
      Icon(Icons.ondemand_video, size: 82, color: accent),
      SizedBox(height: 16), Text('Demo Player', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      SizedBox(height: 8), Text('Licensed video streaming will be added later.', style: TextStyle(color: Colors.white60)),
    ])),
  );
}
