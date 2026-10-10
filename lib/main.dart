import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QasidaApp());
}

class QasidaApp extends StatelessWidget {
  const QasidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qasida Cayniya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF17684B),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  int lastPage = 1;
  int bookmarkCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshState();
  }

  Future<void> _refreshState() async {
    final page = await prefs.getInt('page') ?? 1;
    final bookmarks = await prefs.getStringList('bookmarks') ?? <String>[];
    if (!mounted) return;
    setState(() {
      lastPage = page;
      bookmarkCount = bookmarks.length;
    });
  }

  Future<void> _openReader({int? initialPage}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderPage(initialPage: initialPage),
      ),
    );
    await _refreshState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qasida Cayniya'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qasida Cayniya',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lecture du PDF et écoute audio hors connexion.',
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.offline_bolt_outlined),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Le PDF est intégré à l’application et reste disponible sans Internet.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              icon: Icons.menu_book,
              title: 'Lire la Qasida',
              subtitle: 'Ouvrir le document et naviguer page par page',
              onTap: () => _openReader(),
            ),
            _HomeActionCard(
              icon: Icons.play_circle_fill,
              title: 'Reprendre la lecture',
              subtitle: 'Continuer à la page $lastPage',
              onTap: () => _openReader(initialPage: lastPage),
            ),
            _HomeActionCard(
              icon: Icons.headphones,
              title: 'Écouter Cheikh Bache',
              subtitle: 'Associer puis écouter les parties 1 et 2 en MP3',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AudioPage()),
                );
              },
            ),
            _HomeActionCard(
              icon: Icons.bookmarks,
              title: 'Mes favoris',
              subtitle: '$bookmarkCount page(s) enregistrée(s)',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                );
                await _refreshState();
              },
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version actuelle'),
                subtitle: Text(
                  'PDF intégré. Les deux MP3 peuvent être choisis depuis le téléphone puis associés aux boutons Partie 1 et Partie 2.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, this.initialPage});

  final int? initialPage;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final PdfControllerPinch pdfController;
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  int page = 1;
  int totalPages = 19;
  Set<int> bookmarks = <int>{};
  bool documentLoaded = false;

  @override
  void initState() {
    super.initState();
    page = widget.initialPage ?? 1;
    pdfController = PdfControllerPinch(
      document: PdfDocument.openAsset('qasida.pdf'),
    );
    _restoreBookmarks();
  }

  Future<void> _restoreBookmarks() async {
    final savedBookmarks = await prefs.getStringList('bookmarks') ?? <String>[];
    if (!mounted) return;
    setState(() {
      bookmarks = savedBookmarks.map(int.tryParse).whereType<int>().toSet();
    });
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      if (bookmarks.contains(page)) {
        bookmarks.remove(page);
      } else {
        bookmarks.add(page);
      }
    });
    final sorted = bookmarks.toList()..sort();
    await prefs.setStringList(
      'bookmarks',
      sorted.map((e) => e.toString()).toList(),
    );
  }

  void _goToPage(int target) {
    if (!documentLoaded) return;
    final safePage = target.clamp(1, totalPages);
    pdfController.jumpToPage(safePage);
  }

  @override
  void dispose() {
    pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedBookmarks = bookmarks.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lire la Qasida'),
        actions: [
          IconButton(
            tooltip: bookmarks.contains(page)
                ? 'Retirer des favoris'
                : 'Ajouter aux favoris',
            onPressed: _toggleBookmark,
            icon: Icon(
              bookmarks.contains(page)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
          ),
          PopupMenuButton<int>(
            tooltip: 'Pages favorites',
            onSelected: _goToPage,
            itemBuilder: (_) {
              if (sortedBookmarks.isEmpty) {
                return const [
                  PopupMenuItem<int>(
                    enabled: false,
                    child: Text('Aucun favori'),
                  ),
                ];
              }
              return sortedBookmarks
                  .map(
                    (p) => PopupMenuItem<int>(
                      value: p,
                      child: Text('Page $p'),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfViewPinch(
              controller: pdfController,
              onDocumentLoaded: (document) {
                final target = (widget.initialPage ?? page)
                    .clamp(1, document.pagesCount);
                setState(() {
                  totalPages = document.pagesCount;
                  documentLoaded = true;
                });
                pdfController.jumpToPage(target);
              },
              onPageChanged: (newPage) {
                setState(() => page = newPage);
                prefs.setInt('page', newPage);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Page précédente',
                    onPressed: page > 1 ? () => _goToPage(page - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Page $page / $totalPages',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Page suivante',
                    onPressed: page < totalPages
                        ? () => _goToPage(page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  List<int> pages = <int>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await prefs.getStringList('bookmarks') ?? <String>[];
    final parsed = saved.map(int.tryParse).whereType<int>().toList()..sort();
    if (!mounted) return;
    setState(() {
      pages = parsed;
      loading = false;
    });
  }

  Future<void> _remove(int page) async {
    final updated = pages.where((p) => p != page).toList();
    await prefs.setStringList(
      'bookmarks',
      updated.map((e) => e.toString()).toList(),
    );
    if (!mounted) return;
    setState(() => pages = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pages.isEmpty
              ? const Center(child: Text('Aucune page favorite pour le moment.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: pages.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final p = pages[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text('Page $p'),
                      trailing: IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(p),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReaderPage(initialPage: p),
                          ),
                        );
                        await _load();
                      },
                    );
                  },
                ),
    );
  }
}

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioPlayer player = AudioPlayer();
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  String? part1Path;
  String? part1Name;
  String? part2Path;
  String? part2Name;
  int? activePart;

  @override
  void initState() {
    super.initState();
    _restoreAudioSlots();
  }

  Future<void> _restoreAudioSlots() async {
    final p1 = await prefs.getString('audio_part_1_path');
    final n1 = await prefs.getString('audio_part_1_name');
    final p2 = await prefs.getString('audio_part_2_path');
    final n2 = await prefs.getString('audio_part_2_name');
    if (!mounted) return;
    setState(() {
      part1Path = p1;
      part1Name = n1;
      part2Path = p2;
      part2Name = n2;
    });
  }

  Future<void> _chooseForPart(int part) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final file = result?.files.single;
    final path = file?.path;
    if (file == null || path == null) return;

    if (part == 1) {
      await prefs.setString('audio_part_1_path', path);
      await prefs.setString('audio_part_1_name', file.name);
      if (!mounted) return;
      setState(() {
        part1Path = path;
        part1Name = file.name;
      });
    } else {
      await prefs.setString('audio_part_2_path', path);
      await prefs.setString('audio_part_2_name', file.name);
      if (!mounted) return;
      setState(() {
        part2Path = path;
        part2Name = file.name;
      });
    }
  }

  Future<void> _playPart(int part) async {
    final path = part == 1 ? part1Path : part2Path;
    if (path == null) {
      await _chooseForPart(part);
      return;
    }

    try {
      if (activePart == part && player.playing) {
        await player.pause();
        return;
      }
      if (activePart != part) {
        await player.setFilePath(path);
        if (!mounted) return;
        setState(() => activePart = part);
      }
      await player.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le fichier de la Partie $part n’est plus accessible. Choisissez-le de nouveau.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Widget _audioCard({
    required int part,
    required String title,
    required String? name,
  }) {
    final configured = name != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(child: Text('$part')),
              title: Text(title),
              subtitle: Text(name ?? 'Aucun MP3 associé'),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _chooseForPart(part),
                    icon: const Icon(Icons.audio_file),
                    label: Text(configured ? 'Changer le MP3' : 'Choisir le MP3'),
                  ),
                ),
                const SizedBox(width: 8),
                StreamBuilder<bool>(
                  stream: player.playingStream,
                  initialData: false,
                  builder: (_, snapshot) {
                    final isPlaying =
                        activePart == part && snapshot.data == true;
                    return FilledButton.icon(
                      onPressed: () => _playPart(part),
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(isPlaying ? 'Pause' : 'Écouter'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Écouter Cheikh Bache')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.offline_bolt_outlined),
              title: Text('Lecture hors connexion'),
              subtitle: Text(
                'Choisissez les deux fichiers MP3 présents sur votre téléphone. Ils seront associés à Partie 1 et Partie 2.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          _audioCard(
            part: 1,
            title: 'Cheikh Bache — Partie 1',
            name: part1Name,
          ),
          _audioCard(
            part: 2,
            title: 'Cheikh Bache — Partie 2',
            name: part2Name,
          ),
          const SizedBox(height: 12),
          StreamBuilder<Duration>(
            stream: player.positionStream,
            initialData: Duration.zero,
            builder: (_, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = player.duration ?? Duration.zero;
              final maxMs = duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0;
              final value = position.inMilliseconds
                  .clamp(0, maxMs.toInt())
                  .toDouble();
              return Column(
                children: [
                  Slider(
                    min: 0,
                    max: maxMs,
                    value: value,
                    onChanged: duration.inMilliseconds > 0
                        ? (v) => player.seek(
                              Duration(milliseconds: v.round()),
                            )
                        : null,
                  ),
                  Text(
                    '${_format(position)} / ${_format(duration)}',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
