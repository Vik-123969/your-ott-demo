import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

const supabaseUrl = 'https://sbyzeeipaieyrlicigxo.supabase.co';
const supabasePublishableKey = 'sb_publishable_NFLGfa4faqKZUhErItWJXw_Vku8Pa0v';
const videoBucket = 'ott-videos';
const bg = Color(0xFF090B12);
const panel = Color(0xFF151B2A);
const accent = Color(0xFF8B6CFF);
const muted = Color(0xFF9AA6BF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  runApp(const YourOttApp());
}

final supabase = Supabase.instance.client;

class YourOttApp extends StatelessWidget {
  const YourOttApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Your OTT',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
          appBarTheme: const AppBarTheme(backgroundColor: bg, elevation: 0),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: panel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFF2B3449))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: accent)),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: panel,
            indicatorColor: accent.withValues(alpha: .22),
          ),
        ),
        home: const HomePage(),
      );
}

class OttTitle {
  final String id;
  final String title;
  final String synopsis;
  final String type;
  final String language;
  final int? year;
  final String? rating;
  final List<String> genres;
  final String? poster;
  final String? backdrop;
  final String? playbackAsset;

  const OttTitle({
    required this.id,
    required this.title,
    required this.synopsis,
    required this.type,
    required this.language,
    required this.genres,
    this.year,
    this.rating,
    this.poster,
    this.backdrop,
    this.playbackAsset,
  });

  factory OttTitle.fromMap(Map<String, dynamic> row) => OttTitle(
        id: row['id'].toString(),
        title: (row['title'] ?? '').toString(),
        synopsis: (row['synopsis'] ?? '').toString(),
        type: (row['content_type'] ?? 'movie').toString(),
        language: (row['original_language'] ?? 'Unknown').toString(),
        year: row['release_year'] is int ? row['release_year'] as int : int.tryParse((row['release_year'] ?? '').toString()),
        rating: row['maturity_rating']?.toString(),
        genres: (row['genres'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        poster: row['poster_path']?.toString(),
        backdrop: row['backdrop_path']?.toString(),
        playbackAsset: row['playback_asset_ref']?.toString(),
      );

  String get typeLabel => type == 'series' ? 'Series' : 'Movie';
  String get genreLabel => genres.isEmpty ? 'Explore now' : genres.join(' • ');
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  bool loading = true;
  String? loadError;
  String search = '';
  String language = 'All languages';
  String genre = 'All genres';
  List<OttTitle> titles = [];
  Set<String> saved = {};
  User? user;

  @override
  void initState() {
    super.initState();
    user = supabase.auth.currentUser;
    _refresh();
    supabase.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() => user = state.session?.user);
      _loadWatchlist();
    });
  }

  Future<void> _refresh() async {
    if (mounted) setState(() { loading = true; loadError = null; });
    try {
      final result = await supabase.from('titles').select().eq('status', 'published').order('updated_at', ascending: false).limit(200);
      titles = (result as List).map((row) => OttTitle.fromMap(Map<String, dynamic>.from(row))).toList();
      await _loadWatchlist();
      if (mounted) setState(() => loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() { loading = false; loadError = error.toString(); });
    }
  }

  Future<void> _loadWatchlist() async {
    final current = supabase.auth.currentUser;
    if (current == null) {
      if (mounted) setState(() => saved = {});
      return;
    }
    try {
      final result = await supabase.from('watchlist').select('title_id').eq('user_id', current.id);
      final ids = (result as List).map((row) => row['title_id'].toString()).toSet();
      if (mounted) setState(() => saved = ids);
    } catch (_) {}
  }

  List<OttTitle> get visibleTitles {
    final q = search.trim().toLowerCase();
    return titles.where((item) {
      final text = (item.title + ' ' + item.genreLabel + ' ' + item.language).toLowerCase();
      final matchesText = q.isEmpty || text.contains(q);
      final matchesLanguage = language == 'All languages' || item.language == language;
      final matchesGenre = genre == 'All genres' || item.genres.any((g) => g.toLowerCase() == genre.toLowerCase());
      return matchesText && matchesLanguage && matchesGenre;
    }).toList();
  }

  List<String> get languages {
    final values = titles.map((e) => e.language).toSet().toList()..sort();
    return ['All languages', ...values];
  }

  List<String> get genres {
    final values = titles.expand((e) => e.genres).toSet().toList()..sort();
    return ['All genres', ...values];
  }

  Future<void> _toggleSaved(OttTitle item) async {
    final current = supabase.auth.currentUser;
    if (current == null) {
      _showMessage('Sign in from Profile to save titles to My List.');
      setState(() => tab = 4);
      return;
    }
    final isSaved = saved.contains(item.id);
    try {
      if (isSaved) {
        await supabase.from('watchlist').delete().eq('user_id', current.id).eq('title_id', item.id);
      } else {
        await supabase.from('watchlist').insert({'user_id': current.id, 'title_id': item.id});
      }
      if (mounted) setState(() { isSaved ? saved.remove(item.id) : saved.add(item.id); });
    } catch (error) {
      _showMessage('My List update failed: ' + error.toString());
    }
  }

  void _showMessage(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value), backgroundColor: panel));
  }

  Future<void> _open(OttTitle item) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => TitlePage(title: item, isSaved: saved.contains(item.id), onSave: () => _toggleSaved(item)),
    ));
    _loadWatchlist();
  }

  Widget _searchBox() => TextField(
        onChanged: (value) => setState(() => search = value),
        decoration: const InputDecoration(hintText: 'Search movies, series, genres or languages', prefixIcon: Icon(Icons.search)),
      );

  Widget _dropdown(String value, List<String> options, ValueChanged<String> changed) {
    final safe = options.contains(value) ? value : options.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safe,
          isExpanded: true,
          dropdownColor: panel,
          items: options.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) { if (v != null) changed(v); },
        ),
      ),
    );
  }

  Widget _filters() => Row(children: [
        Expanded(child: _dropdown(language, languages, (v) => setState(() => language = v))),
        const SizedBox(width: 9),
        Expanded(child: _dropdown(genre, genres, (v) => setState(() => genre = v))),
      ]);

  Widget _header(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      );

  Widget _poster(OttTitle item, {double width = 138, double height = 170}) {
    final path = item.poster;
    if (path != null && path.startsWith('https://')) {
      return Image.network(path, width: width, height: height, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(item, width, height));
    }
    return _placeholder(item, width, height);
  }

  Widget _placeholder(OttTitle item, double width, double height) {
    final colors = item.type == 'series'
        ? const [Color(0xFF51407B), Color(0xFF1B2741)]
        : const [Color(0xFF31556C), Color(0xFF171D38)];
    return Container(
      width: width, height: height, alignment: Alignment.center,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Icon(item.type == 'series' ? Icons.live_tv_rounded : Icons.movie_rounded, size: 44, color: Colors.white70),
    );
  }

  Widget _card(OttTitle item) => InkWell(
        onTap: () => _open(item),
        borderRadius: BorderRadius.circular(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(13), child: SizedBox(width: 138, child: _poster(item)))),
          const SizedBox(height: 7),
          Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(item.language + ' • ' + item.typeLabel, maxLines: 1, style: const TextStyle(color: muted, fontSize: 10)),
        ]),
      );

  Widget _horizontal(List<OttTitle> items) {
    if (items.isEmpty) return const SizedBox(height: 75, child: Center(child: Text('No published titles yet', style: TextStyle(color: muted))));
    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => SizedBox(width: 138, child: _card(items[index])),
      ),
    );
  }

  Widget _tile(OttTitle item) => Card(
        color: panel,
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          contentPadding: const EdgeInsets.all(9),
          leading: ClipRRect(borderRadius: BorderRadius.circular(9), child: _poster(item, width: 53, height: 69)),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item.language + ' • ' + item.typeLabel + ' • ' + (item.year?.toString() ?? '—') + '\n' + item.genreLabel,
              maxLines: 2, style: const TextStyle(color: muted, fontSize: 11)),
          isThreeLine: true,
          trailing: IconButton(
            icon: Icon(saved.contains(item.id) ? Icons.bookmark : Icons.bookmark_add_outlined, color: accent),
            onPressed: () => _toggleSaved(item),
          ),
          onTap: () => _open(item),
        ),
      );

  Widget _homeTab(List<OttTitle> list) {
    final movies = list.where((e) => e.type == 'movie').toList();
    final series = list.where((e) => e.type == 'series').toList();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: [
        Container(
          height: 185,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF4934A5), Color(0xFF171D38)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            const Text('ONE APP.\nMANY WORLDS.', style: TextStyle(fontSize: 27, height: 1.05, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Movies and series across languages', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: list.isEmpty ? null : () => _open(list.first), icon: const Icon(Icons.play_arrow), label: const Text('Explore now')),
          ]),
        ),
        const SizedBox(height: 18),
        _searchBox(),
        const SizedBox(height: 13),
        _filters(),
        const SizedBox(height: 22),
        _header('Trending on Your OTT'),
        _horizontal(list.take(10).toList()),
        const SizedBox(height: 22),
        _header('Movies'),
        _horizontal(movies),
        const SizedBox(height: 22),
        _header('Web Series'),
        _horizontal(series),
        const SizedBox(height: 20),
        _header('Explore all titles'),
        if (list.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No published titles match these filters.', style: TextStyle(color: muted)))),
        ...list.map(_tile),
        const SizedBox(height: 12),
        const Text('Your OTT • Live catalogue', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }

  Widget _catalogTab(List<OttTitle> list, String type) {
    final result = list.where((e) => e.type == type).toList();
    final label = type == 'movie' ? 'Movies' : 'Web Series';
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(padding: const EdgeInsets.all(18), children: [
        Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Only titles published by Your OTT are shown.', style: TextStyle(color: muted)),
        const SizedBox(height: 16),
        _searchBox(),
        const SizedBox(height: 13),
        _filters(),
        const SizedBox(height: 18),
        if (result.isEmpty) Text('No published ' + label + ' found.', style: const TextStyle(color: muted)),
        ...result.map(_tile),
      ]),
    );
  }

  Widget _myListTab() {
    if (user == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.bookmark_border, size: 54, color: accent),
          const SizedBox(height: 12),
          const Text('Sign in to use My List', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          const Text('Your saved movies and series will appear here.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => setState(() => tab = 4), child: const Text('Go to Profile')),
        ]),
      ));
    }
    final list = titles.where((e) => saved.contains(e.id)).toList();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('My List', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        if (list.isEmpty) const Text('You have not saved any titles yet.', style: TextStyle(color: muted)),
        ...list.map(_tile),
      ]),
    );
  }

  Widget _profileTab() => ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Your Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(user?.email ?? 'Browsing as guest', style: const TextStyle(color: muted)),
        const SizedBox(height: 17),
        AuthPanel(onChanged: _refresh),
        const SizedBox(height: 18),
        const Text('Playback requires an active subscription or an admin account. Payments are not connected yet.',
            style: TextStyle(color: muted, fontSize: 12)),
      ]);

  @override
  Widget build(BuildContext context) {
    final list = visibleTitles;
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOUR OTT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh), tooltip: 'Refresh catalogue')],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : loadError != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off, size: 54, color: accent),
                  const SizedBox(height: 12),
                  const Text('Could not load Your OTT catalogue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(loadError!, textAlign: TextAlign.center, style: const TextStyle(color: muted)),
                  const SizedBox(height: 14),
                  FilledButton(onPressed: _refresh, child: const Text('Try again')),
                ])))
              : IndexedStack(index: tab, children: [
                  _homeTab(list),
                  _catalogTab(list, 'movie'),
                  _catalogTab(list, 'series'),
                  _myListTab(),
                  _profileTab(),
                ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.movie_outlined), selectedIcon: Icon(Icons.movie), label: 'Movies'),
          NavigationDestination(icon: Icon(Icons.live_tv_outlined), selectedIcon: Icon(Icons.live_tv), label: 'Series'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'My List'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class AuthPanel extends StatefulWidget {
  final Future<void> Function() onChanged;
  const AuthPanel({super.key, required this.onChanged});
  @override
  State<AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends State<AuthPanel> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool createMode = false;
  bool busy = false;
  String? message;
  bool hasError = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!email.text.trim().contains('@')) {
      setState(() { message = 'Enter a valid email address.'; hasError = true; });
      return;
    }
    if (password.text.length < 8) {
      setState(() { message = 'Password must be at least 8 characters.'; hasError = true; });
      return;
    }
    setState(() { busy = true; message = null; });
    try {
      if (createMode) {
        final response = await supabase.auth.signUp(email: email.text.trim(), password: password.text);
        setState(() {
          message = response.session == null
              ? 'Account request sent. Check your email to confirm, then sign in.'
              : 'Your account was created and signed in.';
          hasError = false;
        });
      } else {
        await supabase.auth.signInWithPassword(email: email.text.trim(), password: password.text);
        setState(() { message = 'Signed in successfully.'; hasError = false; });
      }
      await widget.onChanged();
    } on AuthException catch (e) {
      setState(() { message = e.message; hasError = true; });
    } catch (e) {
      setState(() { message = e.toString(); hasError = true; });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    await widget.onChanged();
    if (mounted) setState(() { message = 'Signed out.'; hasError = false; });
  }

  @override
  Widget build(BuildContext context) {
    final current = supabase.auth.currentUser;
    if (current != null) {
      return Card(color: panel, child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.verified_user_outlined, color: accent, size: 34),
          const SizedBox(height: 10),
          const Text('You are signed in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(current.email ?? current.id, style: const TextStyle(color: muted)),
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: busy ? null : _signOut, icon: const Icon(Icons.logout), label: const Text('Sign out')),
        ]),
      ));
    }
    return Card(color: panel, child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(createMode ? 'Create an account' : 'Sign in', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, autocorrect: false,
          decoration: const InputDecoration(labelText: 'Email address')),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: true,
          decoration: const InputDecoration(labelText: 'Password (at least 8 characters)')),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: busy ? null : _submit,
          child: Text(busy ? 'Please wait…' : createMode ? 'Create account' : 'Sign in'),
        )),
        TextButton(
          onPressed: busy ? null : () => setState(() { createMode = !createMode; message = null; }),
          child: Text(createMode ? 'Already registered? Sign in' : 'New to Your OTT? Create an account'),
        ),
        if (message != null) Text(message!, style: TextStyle(fontSize: 12, color: hasError ? const Color(0xFFFF9AA5) : const Color(0xFF65E4BA))),
      ]),
    ));
  }
}

class TitlePage extends StatefulWidget {
  final OttTitle title;
  final bool isSaved;
  final Future<void> Function() onSave;
  const TitlePage({super.key, required this.title, required this.isSaved, required this.onSave});

  @override
  State<TitlePage> createState() => _TitlePageState();
}

class _TitlePageState extends State<TitlePage> {
  bool saved = false;
  bool loading = false;
  String? error;
  String? selectedSeasonId;
  List<Map<String, dynamic>> seasons = [];
  List<Map<String, dynamic>> episodes = [];

  @override
  void initState() {
    super.initState();
    saved = widget.isSaved;
    if (widget.title.type == 'series') _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await supabase.from('seasons').select().eq('title_id', widget.title.id).order('season_number');
      seasons = (result as List).map((e) => Map<String, dynamic>.from(e)).toList();
      if (seasons.isNotEmpty) {
        selectedSeasonId = seasons.first['id'].toString();
        await _loadEpisodes(selectedSeasonId!, showLoading: false);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadEpisodes(String seasonId, {bool showLoading = true}) async {
    if (showLoading && mounted) setState(() { loading = true; error = null; });
    selectedSeasonId = seasonId;
    try {
      final result = await supabase.from('episodes').select()
          .eq('season_id', seasonId).eq('status', 'published').order('episode_number');
      episodes = (result as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String> _resolveAsset(String asset) async {
    if (asset.startsWith('https://')) return asset;
    return supabase.storage.from(videoBucket).createSignedUrl(asset, 3600);
  }

  Future<void> _play(String asset, String mediaTitle) async {
    if (supabase.auth.currentUser == null) {
      _message('Sign in before playing videos.');
      return;
    }
    try {
      final url = await _resolveAsset(asset);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(title: mediaTitle, url: url)));
    } on StorageException catch (e) {
      _message('Playback denied: ' + e.message + '. An active subscription or admin account is required.');
    } catch (e) {
      _message('Could not start playback: ' + e.toString());
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value), backgroundColor: panel),
      );

  Future<void> _save() async {
    await widget.onSave();
    if (mounted) setState(() => saved = !saved);
  }

  Widget _playButton(String? asset, String label) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: asset == null || asset.isEmpty ? null : () => _play(asset, label),
          icon: const Icon(Icons.play_arrow),
          label: Text(asset == null || asset.isEmpty ? 'Coming soon' : 'Play now'),
        ),
      );

  Widget _hero(OttTitle item) {
    final path = item.backdrop ?? item.poster;
    if (path != null && path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _heroFallback(item));
    }
    return _heroFallback(item);
  }

  Widget _heroFallback(OttTitle item) => Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4934A5), Color(0xFF171D38)])),
        child: Icon(item.type == 'series' ? Icons.live_tv_rounded : Icons.movie_rounded, size: 76, color: Colors.white70),
      );

  Widget _episodeCard(Map<String, dynamic> episode) {
    final asset = episode['playback_asset_ref']?.toString();
    final number = episode['episode_number'].toString();
    final duration = episode['duration_seconds'];
    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: accent.withValues(alpha: .2), child: Text(number)),
        title: Text(episode['title']?.toString() ?? 'Episode ' + number),
        subtitle: Text(duration is int ? ((duration / 60).round()).toString() + ' min' : 'Episode', style: const TextStyle(color: muted)),
        trailing: IconButton(
          onPressed: asset == null || asset.isEmpty ? null : () => _play(asset, episode['title'].toString()),
          icon: const Icon(Icons.play_circle_fill, color: accent, size: 32),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.title;
    final meta = item.language + ' • ' + item.typeLabel + ' • ' + (item.year?.toString() ?? '—')
        + (item.rating == null ? '' : ' • ' + item.rating!);
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 210, child: _hero(item))),
        const SizedBox(height: 18),
        Text(item.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(meta, style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 8),
        Text(item.genreLabel, style: const TextStyle(color: accent, fontWeight: FontWeight.w600)),
        const SizedBox(height: 15),
        Text(item.synopsis.isEmpty ? 'More details coming soon.' : item.synopsis, style: const TextStyle(height: 1.5)),
        const SizedBox(height: 16),
        if (item.type == 'movie') _playButton(item.playbackAsset, item.title),
        OutlinedButton.icon(onPressed: _save, icon: Icon(saved ? Icons.bookmark : Icons.bookmark_add_outlined),
            label: Text(saved ? 'Saved to My List' : 'Add to My List')),
        if (item.type == 'series') ...[
          const SizedBox(height: 16),
          const Text('Seasons & Episodes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (loading) const Center(child: CircularProgressIndicator(color: accent)),
          if (error != null) Text(error!, style: const TextStyle(color: Color(0xFFFF9AA5))),
          if (!loading && seasons.isEmpty) const Text('No published seasons yet.', style: TextStyle(color: muted)),
          if (seasons.isNotEmpty)
            DropdownButtonFormField<String>(
              value: selectedSeasonId,
              decoration: const InputDecoration(labelText: 'Choose season'),
              items: seasons.map((s) => DropdownMenuItem(
                value: s['id'].toString(),
                child: Text(s['title']?.toString().isNotEmpty == true ? s['title'].toString() : 'Season ' + s['season_number'].toString()),
              )).toList(),
              onChanged: (value) { if (value != null) _loadEpisodes(value); },
            ),
          const SizedBox(height: 12),
          ...episodes.map(_episodeCard),
        ],
        const SizedBox(height: 24),
        const Text('Your OTT • Published catalogue', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }
}

class PlayerPage extends StatefulWidget {
  final String title;
  final String url;
  const PlayerPage({super.key, required this.title, required this.url});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? player;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || !uri.hasScheme) {
      setState(() { error = 'Invalid playback URL.'; loading = false; });
      return;
    }
    final isHls = uri.path.toLowerCase().endsWith('.m3u8');
    final controller = VideoPlayerController.networkUrl(uri, formatHint: isHls ? VideoFormat.hls : null);
    player = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (mounted) {
        setState(() => loading = false);
        await controller.play();
      }
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = player;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: loading
            ? const CircularProgressIndicator(color: accent)
            : error != null
                ? Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF9AA5))))
                : video == null
                    ? const Text('Player unavailable.')
                    : ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
                        ClipRRect(borderRadius: BorderRadius.circular(14), child: AspectRatio(
                          aspectRatio: video.value.aspectRatio > 0 ? video.value.aspectRatio : 16 / 9,
                          child: VideoPlayer(video),
                        )),
                        const SizedBox(height: 12),
                        VideoProgressIndicator(video, allowScrubbing: true, colors: const VideoProgressColors(
                          playedColor: accent, bufferedColor: Colors.white38, backgroundColor: Colors.white12,
                        )),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          IconButton(onPressed: () => video.seekTo(video.value.position - const Duration(seconds: 10)), icon: const Icon(Icons.replay_10)),
                          IconButton.filled(onPressed: () => setState(() {
                            video.value.isPlaying ? video.pause() : video.play();
                          }), icon: Icon(video.value.isPlaying ? Icons.pause : Icons.play_arrow)),
                          IconButton(onPressed: () => video.seekTo(video.value.position + const Duration(seconds: 10)), icon: const Icon(Icons.forward_10)),
                          IconButton(onPressed: () => video.setPlaybackSpeed(video.value.playbackSpeed == 1.0 ? 1.5 : 1.0), icon: const Icon(Icons.speed)),
                        ]),
                        const Text('Your OTT Player • HLS / MP4', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11)),
                      ]),
      ),
    );
  }
}
