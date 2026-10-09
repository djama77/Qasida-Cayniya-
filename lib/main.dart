import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

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
      home: const ReaderPage(),
    );
  }
}

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final PdfControllerPinch pdfController;
  final AudioPlayer audioPlayer = AudioPlayer();
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();

  int page = 1;
  int totalPages = 19;
  Set<int> bookmarks = <int>{};
  String? currentAudio;

  @override
  void initState() {
    super.initState();
    pdfController = PdfControllerPinch(
      document: PdfDocument.openAsset('qasida.pdf'),
    );
    _restoreState();
  }

  Future<void> _restoreState() async {
    final savedPage = await prefs.getInt('page') ?? 1;
    final savedBookmarks = await prefs.getStringList('bookmarks') ?? <String>[];

    if (!mounted) return;

    setState(() {
      bookmarks = savedBookmarks
          .map(int.tryParse)
          .whereType<int>()
          .toSet();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        pdfController.jumpToPage(savedPage.clamp(1, totalPages));
      }
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

    await prefs.setStringList(
      'bookmarks',
      bookmarks.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _chooseAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final path = result?.files.single.path;
    if (path == null) return;

    try {
      await audioPlayer.setFilePath(path);
      if (!mounted) return;
      setState(() => currentAudio = result!.files.single.name);
      await audioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lire ce fichier audio.')),
      );
    }
  }

  void _goToPage(int target) {
    if (target >= 1 && target <= totalPages) {
      pdfController.jumpToPage(target);
    }
  }

  @override
  void dispose() {
    pdfController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedBookmarks = bookmarks.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qasida Cayniya'),
        actions: [
          IconButton(
            tooltip: 'Ajouter aux favoris',
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
            itemBuilder: (_) => sortedBookmarks
                .map(
                  (p) => PopupMenuItem<int>(
                    value: p,
                    child: Text('Page $p'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfViewPinch(
              controller: pdfController,
              onDocumentLoaded: (document) {
                if (mounted) {
                  setState(() => totalPages = document.pagesCount);
                }
              },
              onPageChanged: (newPage) {
                setState(() => page = newPage);
                prefs.setInt('page', newPage);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: page > 1 ? () => _goToPage(page - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Page $page / $totalPages'),
                    IconButton(
                      onPressed: page < totalPages
                          ? () => _goToPage(page + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _chooseAudio,
                        icon: const Icon(Icons.audio_file),
                        label: const Text('Choisir un MP3'),
                      ),
                      const SizedBox(width: 8),
                      StreamBuilder<bool>(
                        stream: audioPlayer.playingStream,
                        initialData: false,
                        builder: (_, snapshot) => IconButton(
                          tooltip: 'Lecture / pause',
                          onPressed: currentAudio == null
                              ? null
                              : () async {
                                  if (audioPlayer.playing) {
                                    await audioPlayer.pause();
                                  } else {
                                    await audioPlayer.play();
                                  }
                                },
                          icon: Icon(
                            snapshot.data == true
                                ? Icons.pause_circle
                                : Icons.play_circle,
                          ),
                        ),
                      ),
                      if (currentAudio != null)
                        Expanded(
                          child: Text(
                            currentAudio!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
