import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'القرآن الكريم',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'EG'),
      ],
      locale: const Locale('ar', 'EG'),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B2B1F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4332),
          primary: const Color(0xFFD4AF37),
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainHomeScreen(),
    );
  }
}

class QuranLogo extends StatelessWidget {
  final double size;
  const QuranLogo({super.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.6), width: 1.5),
                ),
              ),
            ),
            Container(
              width: size * 0.45,
              height: size * 0.45,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.6), width: 1.5),
              ),
            ),
            Icon(
              Icons.menu_book_rounded,
              color: const Color(0xFFD4AF37),
              size: size * 0.4,
            ),
          ],
        ),
      ),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const QuranPdfReaderScreen(),
    const SurahListScreen(),
    const KhatmahTrackerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1B4332),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.white60,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'المصحف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.headset),
            label: 'الصوتيات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_added),
            label: 'الختمة',
          ),
        ],
      ),
    );
  }
}

class QuranPdfReaderScreen extends StatefulWidget {
  const QuranPdfReaderScreen({super.key});

  @override
  State<QuranPdfReaderScreen> createState() => _QuranPdfReaderScreenState();
}

class _QuranPdfReaderScreenState extends State<QuranPdfReaderScreen> {
  String localPdfPath = "";
  bool isLoading = true;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  int totalPages = 0;
  int currentPage = 0;

  // رابط تنزيل المصحف المباشر (يمكنك تغييره لأي رابط آخر)
  final String pdfUrl = "https://raw.githubusercontent.com/Koran-PDF/Quran/main/quran.pdf";

  @override
  void initState() {
    super.initState();
    _checkAndPreparePdf();
  }

  Future<void> _checkAndPreparePdf() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/quran_downloaded.pdf');

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            localPdfPath = file.path;
            isLoading = false;
          });
        }
      } else {
        _downloadPdfOnline(file);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _downloadPdfOnline(File saveFile) async {
    setState(() {
      isLoading = false;
      isDownloading = true;
    });

    try {
      await Dio().download(
        pdfUrl,
        saveFile.path,
        onReceiveProgress: (rec, total) {
          if (total > 0 && mounted) {
            setState(() => downloadProgress = rec / total);
          }
        },
      );

      if (mounted) {
        setState(() {
          localPdfPath = saveFile.path;
          isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تحميل المصحف، تحقق من اتصالك بالإنترنت')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 4,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const QuranLogo(size: 32),
            const SizedBox(width: 10),
            Text(
              totalPages > 0 ? 'المصحف الشريف (${currentPage + 1}/$totalPages)' : 'المصحف الشريف',
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: isDownloading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const QuranLogo(size: 85),
                  const SizedBox(height: 25),
                  Text(
                    'جاري تحميل ملف المصحف لأول مرة...
${(downloadProgress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(
                      value: downloadProgress,
                      color: const Color(0xFFD4AF37),
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ],
              ),
            )
          : localPdfPath.isNotEmpty
              ? PDFView(
                  filePath: localPdfPath,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: false,
                  pageFling: true,
                  onRender: (pages) => setState(() => totalPages = pages!),
                  onPageChanged: (page, total) => setState(() => currentPage = page!),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const QuranLogo(size: 80),
                      const SizedBox(height: 20),
                      const Text(
                        'تعذر تحميل ملف المصحف، تحقق من الاتصال ثم أعد فتح الشاشة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                        onPressed: _checkAndPreparePdf,
                        child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.black)),
                      )
                    ],
                  ),
                ),
    );
  }
}

final List<String> allSurahs = [
  "الفاتحة", "البقرة", "آل عمران", "النساء", "المائدة", "الأنعام", "الأعراف", "الأنفال",
  "التوبة", "يونس", "هود", "يوسف", "الرعد", "إبراهيم", "الحجر", "النحل", "الإسراء",
  "الكهف", "مريم", "طه", "الأنبياء", "الحج", "المؤمنون", "النور", "الفرقان", "الشعراء",
  "النمل", "القصص", "العنكبوت", "الروم", "لقمان", "السجدة", "الأحزاب", "سبأ", "فاطر",
  "يس", "الصافات", "ص", "الزمر", "غافر", "فصلت", "الشورى", "الزخرف", "الدخان",
  "الجاثية", "الأحقاف", "محمد", "الفتح", "الحجرات", "ق", "الذاريات", "الطور", "النجم",
  "القمر", "الرحمن", "الواقعة", "الحديد", "المجادلة", "الحشر", "الممتحنة", "الصف",
  "الجمعة", "المنافقون", "التغابن", "الطلاق", "التحريم", "الملك", "القلم", "الحاقة",
  "المعارج", "نوح", "الجن", "المزمل", "المدثر", "القيامة", "الإنسان", "المرسلات", "النبأ",
  "النازعات", "عبس", "التكوير", "الإنفطار", "المطففين", "الإنشقاق", "البروج", "الطارق",
  "الأعلى", "الغاشية", "الفجر", "البلد", "الشمس", "الليل", "الضحى", "الشرح", "التين",
  "العلق", "القدر", "البينة", "الزلزلة", "العاديات", "القارعة", "التكاثر", "العصر",
  "الهمزة", "الفيل", "قريش", "المواعون", "الكوثر", "الكافرون", "النصر", "المسد",
  "الإخلاص", "الفلق", "الناس"
];

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _searchQuery = "";

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'[أإآا]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSurahs = allSurahs.asMap().entries.where((entry) {
      final surahNameClean = _cleanText(entry.value);
      final queryClean = _cleanText(_searchQuery);
      return surahNameClean.contains(queryClean);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 4,
        title: const Text('المصحف الصوتي', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(65),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم السورة...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: const Color(0xFF0B2B1F),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredSurahs.length,
        itemBuilder: (context, index) {
          final surahIndex = filteredSurahs[index].key + 1;
          final surahName = filteredSurahs[index].value;
          final formattedNumber = surahIndex.toString().padLeft(3, '0');

          return SurahTile(
            key: ValueKey(formattedNumber),
            surahNumber: formattedNumber,
            surahName: surahName,
            audioPlayer: _audioPlayer,
          );
        },
      ),
    );
  }
}

class SurahTile extends StatefulWidget {
  final String surahNumber;
  final String surahName;
  final AudioPlayer audioPlayer;

  const SurahTile({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.audioPlayer,
  });

  @override
  State<SurahTile> createState() => _SurahTileState();
}

class _SurahTileState extends State<SurahTile> {
  bool isDownloading = false;
  double downloadProgress = 0.0;
  bool isDownloaded = false;
  bool isPlaying = false;
  bool isLooping = false;
  String localPath = '';

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  Future<void> _checkFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.surahNumber}.mp3');
    if (await file.exists()) {
      if (mounted) {
        setState(() {
          isDownloaded = true;
          localPath = file.path;
        });
      }
    }
  }

  Future<void> _toggleAudio() async {
    String remoteUrl = "https://server7.mp3quran.net/basit/${widget.surahNumber}.mp3";

    try {
      if (isPlaying) {
        await widget.audioPlayer.pause();
        setState(() => isPlaying = false);
      } else {
        if (isDownloaded) {
          await widget.audioPlayer.setFilePath(localPath);
        } else {
          await widget.audioPlayer.setUrl(remoteUrl);
        }
        widget.audioPlayer.play();
        setState(() => isPlaying = true);

        widget.audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (mounted) setState(() => isPlaying = false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الاتصال بالسيرفر، تحقق من الإنترنت')),
        );
      }
    }
  }

  Future<void> _toggleLoop() async {
    setState(() => isLooping = !isLooping);
    if (isLooping) {
      await widget.audioPlayer.setLoopMode(LoopMode.one);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفعيل تكرار السورة للحفظ')),
        );
      }
    } else {
      await widget.audioPlayer.setLoopMode(LoopMode.off);
    }
  }

  Future<void> _download() async {
    setState(() => isDownloading = true);
    final dir = await getApplicationDocumentsDirectory();
    String savePath = '${dir.path}/${widget.surahNumber}.mp3';
    String url = "https://server7.mp3quran.net/basit/${widget.surahNumber}.mp3";

    try {
      await Dio().download(url, savePath, onReceiveProgress: (rec, total) {
        if (total > 0 && mounted) {
          setState(() => downloadProgress = rec / total);
        }
      });
      if (mounted) {
        setState(() {
          isDownloading = false;
          isDownloaded = true;
          localPath = savePath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحميل سورة ${widget.surahName} بنجاح!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل التنزيل، يرجى المحاولة لاحقاً')),
        );
      }
    }
  }

  Future<void> _deleteFile() async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
      if (mounted) {
        setState(() {
          isDownloaded = false;
          localPath = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف سورة ${widget.surahName} لتوفير المساحة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1B4332),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          widget.surahName,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isDownloaded ? "متاحة بدون إنترنت" : "تشغيل عبر النت",
          style: TextStyle(color: isDownloaded ? Colors.greenAccent : Colors.white54, fontSize: 12),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFD4AF37),
          child: Text(
            int.parse(widget.surahNumber).toString(),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.repeat, color: isLooping ? Colors.greenAccent : Colors.white38),
              onPressed: _toggleLoop,
              tooltip: 'تكرار للحفظ',
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: const Color(0xFFD4AF37),
                size: 34,
              ),
              onPressed: _toggleAudio,
            ),
            isDownloading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(value: downloadProgress, color: const Color(0xFFD4AF37)),
                  )
                : IconButton(
                    icon: Icon(
                      isDownloaded ? Icons.check_circle : Icons.download_for_offline,
                      color: isDownloaded ? Colors.greenAccent : Colors.white70,
                    ),
                    onPressed: isDownloaded ? _deleteFile : _download,
                    tooltip: isDownloaded ? 'حذف من الجهاز' : 'تحميل أوفلاين',
                  ),
          ],
        ),
      ),
    );
  }
}

class KhatmahTrackerScreen extends StatefulWidget {
  const KhatmahTrackerScreen({super.key});

  @override
  State<KhatmahTrackerScreen> createState() => _KhatmahTrackerScreenState();
}

class _KhatmahTrackerScreenState extends State<KhatmahTrackerScreen> {
  int completedPages = 1;
  final int totalPages = 604;

  @override
  Widget build(BuildContext context) {
    double progress = completedPages / totalPages;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 4,
        title: const Text('متابعة الختمة', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const QuranLogo(size: 85),
              const SizedBox(height: 25),
              const Text(
                'نسبة الإنجاز في الختمة الحالية',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$completedPages / $totalPages',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        if (completedPages < totalPages) completedPages++;
                      });
                    },
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text('صفحة جديدة', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 15),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        if (completedPages > 1) completedPages--;
                      });
                    },
                    icon: const Icon(Icons.remove, color: Colors.white),
                    label: const Text('تراجع', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
