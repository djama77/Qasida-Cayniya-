import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const QasidaApp()); }
class QasidaApp extends StatelessWidget {
  const QasidaApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'Qasida - مصححة الأفراح', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: const Color(0xff17684b), useMaterial3: true),
    home: const ReaderPage());
}
class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});
  @override State<ReaderPage> createState() => _ReaderPageState();
}
class _ReaderPageState extends State<ReaderPage> {
  late final PdfControllerPinch pdf;
  final AudioPlayer player = AudioPlayer();
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  int page = 1;
  int total = 19;
  Set<int> bookmarks = {};
  bool audioReady = false;
  String? audioName;
  int? selectedTrack;
  final tracks = const [
    ("Partie 1 — Cheikh Bache", "assets/audio/cheikh_bache_partie_1.mp3"),
    ("Partie 2 — Cheikh Bache", "assets/audio/cheikh_bache_partie_2.mp3"),
  ];
  Future<void> _playTrack(int index) async {
    try {
      await player.setAsset(tracks[index].$2);
      if (!mounted) return;
      setState(() { audioReady = true; selectedTrack = index; audioName = tracks[index].$1; });
      await player.play();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de lire l’enregistrement.")));
    }
  }
  @override void initState() {
    super.initState();
    pdf = PdfControllerPinch(document: PdfDocument.openAsset('assets/qasida.pdf'));
    _load();
  }
  Future<void> _load() async {
    final saved = await prefs.getInt('page') ?? 1;
    final stored = await prefs.getStringList('bookmarks') ?? [];
    if (!mounted) return;
    setState(() => bookmarks = stored.map(int.tryParse).whereType<int>().toSet());
    // Jump after the document viewer is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _go(saved.clamp(1, total));
    });
  }
  void _go(int target) {
    if (target < 1 || target > total) return;
    pdf.jumpToPage(target);
  }
  Future<void> _bookmark() async {
    setState(() => bookmarks.contains(page) ? bookmarks.remove(page) : bookmarks.add(page));
    await prefs.setStringList('bookmarks', bookmarks.map((e) => e.toString()).toList());
  }
  Future<void> _chooseAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final path = result?.files.single.path;
    if (path == null) return;
    try {
      await player.setFilePath(path);
      if (!mounted) return;
      setState(() { audioReady = true; selectedTrack = null; audioName = result!.files.single.name; });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de lire ce fichier audio.')));
    }
  }
  @override void dispose() { pdf.dispose(); player.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مصححة الأفراح'), actions: [
      IconButton(tooltip: 'Favori', icon: Icon(bookmarks.contains(page) ? Icons.bookmark : Icons.bookmark_border), onPressed: _bookmark),
      PopupMenuButton<int>(tooltip: 'Favoris', icon: const Icon(Icons.list), onSelected: _go,
        itemBuilder: (_) { final pages = bookmarks.toList()..sort(); return pages.map((p) => PopupMenuItem<int>(value: p, child: Text("Page $p"))).toList(); }
      ),
    ]),
    body: Column(children: [
      Expanded(child: PdfViewPinch(controller: pdf,
        onDocumentLoaded: (document) { if(mounted) setState(() => total = document.pagesCount); },
        onPageChanged: (p) { setState(() => page = p); prefs.setInt('page', p); },
      )),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(tooltip: 'Page précédente', onPressed: page > 1 ? () => _go(page - 1) : null, icon: const Icon(Icons.chevron_left)),
        Text('Page $page / $total'),
        IconButton(tooltip: 'Page suivante', onPressed: page < total ? () => _go(page + 1) : null, icon: const Icon(Icons.chevron_right)),
      ]),
      const Divider(height: 1),
      Row(children: [
        Expanded(child: DropdownButton<int>(isExpanded: true, hint: const Text("Écouter une partie"), value: selectedTrack, items: List.generate(tracks.length, (i) => DropdownMenuItem(value: i, child: Text(tracks[i].$1, overflow: TextOverflow.ellipsis))), onChanged: (i) { if (i != null) _playTrack(i); })),
      ]),
      Row(children: [
        TextButton.icon(onPressed: _chooseAudio, icon: const Icon(Icons.audio_file), label: const Text('Choisir un audio')),
        if (audioReady) IconButton(tooltip: 'Lecture / pause', icon: StreamBuilder<bool>(
          stream: player.playingStream, initialData: false,
          builder: (_, snapshot) => Icon(snapshot.data == true ? Icons.pause : Icons.play_arrow)),
          onPressed: () async { if(player.playing) { await player.pause(); } else { await player.play(); } }),
        if(audioName != null) Expanded(child: Text(audioName!, overflow: TextOverflow.ellipsis)),
      ]),
    ]),
  );
}
