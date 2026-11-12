import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  } catch (_) {}

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();

  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool('daily_reminders') ?? true;
  if (enabled) {
    await scheduleDailyReminders();
  }
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}

Future<void> scheduleDailyReminders() async {
  await flutterLocalNotificationsPlugin.cancelAll();

  const androidDetails = AndroidNotificationDetails(
    'rz_kharch_daily_reminder',
    'Daily Expense Reminders',
    channelDescription: 'Morning and evening reminders to log daily expenses',
    importance: Importance.high,
    priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails);

  // Morning 9:00 AM Reminder
  await flutterLocalNotificationsPlugin.zonedSchedule(
    101,
    'Rz Kharch Diary - Good Morning! ☀️',
    'Aaj ka budget plan karein aur naye kharch note karein.',
    _nextInstanceOfTime(9, 0),
    details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  // Evening 8:30 PM Reminder
  await flutterLocalNotificationsPlugin.zonedSchedule(
    102,
    'Rz Kharch Diary - Daily Hisaab 📝',
    'Aaj ka kharcha likha kya? Abhi Rz Kharch Diary mein entry karein!',
    _nextInstanceOfTime(20, 30),
    details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await initNotifications();
  runApp(const MaterialApp(
    title: 'Rz Kharch Diary',
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

// Multi-language dictionary
const Map<String, Map<String, String>> appStrings = {
  'hi': {
    'app_name': 'Rz Kharch Diary',
    'balance': 'बचा हुआ बैलेंस',
    'income': 'कमाई',
    'expense': 'खर्च',
    'search': 'सर्च करें...',
    'all': 'सभी',
    'empty': 'कोई लेन-देन नहीं मिला!\n+ दबाकर जोड़ें।',
    'new_tx': 'नया लेन-देन',
    'amount': 'रकम (₹) *',
    'desc': 'विवरण (खाली छोड़ने पर कैटिगरी)',
    'cat': 'कैटिगरी',
    'mode': 'पेमेंट मोड',
    'save': 'सेव करें',
    'details': 'लेन-देन का पूरा ब्योरा',
    'delete': 'हटाएँ (Delete)',
    'select_lang': 'भाषा चुनें (Select Language)',
    'reminder_on': 'सुबह (9:00 AM) और शाम (8:30 PM) रिमाइंडर चालू है 🔔',
    'reminder_off': 'डेली नोटिफिकेशन रिमाइंडर बंद है 🔕',
    'no_data_pdf': 'PDF बनाने के लिए पहले कोई लेन-देन जोड़ें!',
  },
  'en': {
    'app_name': 'Rz Kharch Diary',
    'balance': 'Remaining Balance',
    'income': 'Income',
    'expense': 'Expense',
    'search': 'Search transactions...',
    'all': 'All',
    'empty': 'No transactions found!\nTap + to add.',
    'new_tx': 'New Transaction',
    'amount': 'Amount (₹) *',
    'desc': 'Note (defaults to category if empty)',
    'cat': 'Category',
    'mode': 'Payment Mode',
    'save': 'Save Entry',
    'details': 'Transaction Details',
    'delete': 'Delete Entry',
    'select_lang': 'Select Language',
    'reminder_on': 'Daily Morning (9 AM) & Evening (8:30 PM) Reminder ON 🔔',
    'reminder_off': 'Daily Notification Reminders OFF 🔕',
    'no_data_pdf': 'Add at least one transaction to export PDF!',
  },
  'ur': {
    'app_name': 'Rz Kharch Diary',
    'balance': 'بقیہ بیلنس',
    'income': 'آمدنی',
    'expense': 'خرچ',
    'search': 'تلاش کریں...',
    'all': 'سبھی',
    'empty': 'کوئی لین دین نہیں ملا!\n+ دبا کر شامل کریں۔',
    'new_tx': 'نیا لین دین',
    'amount': 'رقم (₹) *',
    'desc': 'تفصیل (خالی چھوڑنے پر کیٹیگری)',
    'cat': 'کیٹیگری',
    'mode': 'ادائیگی کا طریقہ',
    'save': 'محفوظ کریں',
    'details': 'لین دین کی مکمل تفصیل',
    'delete': 'حذف کریں (Delete)',
    'select_lang': 'زبان منتخب کریں',
    'reminder_on': 'صبح 9 بجے اور شام 8:30 بجے ریمائنڈر آن ہے 🔔',
    'reminder_off': 'ڈیلی ریمائنڈر بند ہے 🔕',
    'no_data_pdf': 'PDF بنانے کے لیے پہلے کوئی اندراج کریں!',
  },
  'mr': {
    'app_name': 'Rz Kharch Diary',
    'balance': 'शिल्लक रक्कम',
    'income': 'उत्पन्न',
    'expense': 'खर्च',
    'search': 'शोधा...',
    'all': 'सर्व',
    'empty': 'कोणताही व्यवहार सापडला नाही!\n+ दाबून जोडा.',
    'new_tx': 'नवीन व्यवहार',
    'amount': 'रक्कम (₹) *',
    'desc': 'तपशील',
    'cat': 'श्रेणी',
    'mode': 'पेमेंट पद्धत',
    'save': 'जतन करा',
    'details': 'व्यवहाराचा तपशील',
    'delete': 'हटवा (Delete)',
    'select_lang': 'भाषा निवडा',
    'reminder_on': 'सकाळी 9 आणि संध्याकाळी 8:30 रिमाइंडर चालू 🔔',
    'reminder_off': 'रिमाइंडर बंद आहे 🔕',
    'no_data_pdf': 'PDF साठी आधी व्यवहार जोडा!',
  },
  'gu': {
    'app_name': 'Rz Kharch Diary',
    'balance': 'બાકી બેલેન્સ',
    'income': 'આવક',
    'expense': 'ખર્ચ',
    'search': 'શોધો...',
    'all': 'બધા',
    'empty': 'કોઈ વ્યવહાર મળ્યો નથી!\n+ દબાવીને ઉમેરો.',
    'new_tx': 'નવો વ્યવહાર',
    'amount': 'રકમ (₹) *',
    'desc': 'વિગત',
    'cat': 'કેટેગરી',
    'mode': 'પેમેન્ટ મોડ',
    'save': 'સેવ કરો',
    'details': 'વ્યવહારની સંપૂર્ણ વિગત',
    'delete': 'કાઢી નાખો (Delete)',
    'select_lang': 'ભાષા પસંદ કરો',
    'reminder_on': 'સવારે 9 અને સાંજે 8:30 રિમાઇન્ડર ચાલુ છે 🔔',
    'reminder_off': 'રિમાઇન્ડર બંધ છે 🔕',
    'no_data_pdf': 'PDF માટે પહેલા વ્યવહાર ઉમેરો!',
  },
  'bn': {
    'app_name': 'Rz Kharch Diary',
    'balance': 'অবশিষ্ট ব্যালেন্স',
    'income': 'আয়',
    'expense': 'খরচ',
    'search': 'খুঁজুন...',
    'all': 'সব',
    'empty': 'কোনো লেনদেন পাওয়া যায়নি!\n+ চেপে যোগ করুন।',
    'new_tx': 'নতুন লেনদেন',
    'amount': 'পরিমাণ (₹) *',
    'desc': 'বিবরণ',
    'cat': 'বিভাগ',
    'mode': 'পেমেন্ট মাধ্যম',
    'save': 'সেভ করুন',
    'details': 'লেনদেনের বিস্তারিত',
    'delete': 'মুছে ফেলুন',
    'select_lang': 'ভাষা নির্বাচন করুন',
    'reminder_on': 'সকাল ৯টা ও রাত ৮:৩০ রিমাইন্ডার চালু 🔔',
    'reminder_off': 'রিমাইন্ডার বন্ধ আছে 🔕',
    'no_data_pdf': 'PDF এর জন্য আগে লেনদেন যোগ করুন!',
  },
  'ta': {
    'app_name': 'Rz Kharch Diary',
    'balance': 'மீதமுள்ள இருப்பு',
    'income': 'வருமானம்',
    'expense': 'செலவு',
    'search': 'தேடுக...',
    'all': 'அனைத்தும்',
    'empty': 'பரிவர்த்தனைகள் இல்லை!\n+ அழுத்தி சேர்க்கவும்.',
    'new_tx': 'புதிய பரிவர்த்தனை',
    'amount': 'தொகை (₹) *',
    'desc': 'விவரம்',
    'cat': 'வகை',
    'mode': 'கட்டண முறை',
    'save': 'சேமி',
    'details': 'பரிவர்த்தனை விவரங்கள்',
    'delete': 'நீக்கு',
    'select_lang': 'மொழியைத் தேர்ந்தெடுக்கவும்',
    'reminder_on': 'காலை 9 & இரவு 8:30 நினைவூட்டல் இயக்கப்பட்டது 🔔',
    'reminder_off': 'நினைவூட்டல் நிறுத்தப்பட்டது 🔕',
    'no_data_pdf': 'PDF உருவாக்க முதலில் பதிவைச் சேர்க்கவும்!',
  },
  'te': {
    'app_name': 'Rz Kharch Diary',
    'balance': 'మిగిలిన బ్యాలెన్స్',
    'income': 'ఆదాయం',
    'expense': 'ఖర్చు',
    'search': 'వెతకండి...',
    'all': 'అన్నీ',
    'empty': 'లావాదేవీలు లేవు!\n+ నొక్కి జోడించండి.',
    'new_tx': 'కొత్త లావాదేవీ',
    'amount': 'మొత్తం (₹) *',
    'desc': 'వివరాలు',
    'cat': 'వర్గం',
    'mode': 'చెల్లింపు విధానం',
    'save': 'సేవ్ చేయండి',
    'details': 'లావాదేవీ పూర్తి వివరాలు',
    'delete': 'తొలగించు',
    'select_lang': 'భాషను ఎంచుకోండి',
    'reminder_on': 'ఉదయం 9 & రాత్రి 8:30 రిమైండర్ ఆన్‌లో ఉంది 🔔',
    'reminder_off': 'రిమైండర్ ఆఫ్‌లో ఉంది 🔕',
    'no_data_pdf': 'PDF కోసం ముందుగా లావాదేవీని జోడించండి!',
  },
};

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _a,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF0F766E).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 50),
              ),
              const SizedBox(height: 16),
              const Text('Rz Kharch Diary',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E))),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List> _list = [];
  String _query = '';
  String _filter = 'ALL';
  String _lang = 'hi';
  bool _remindersEnabled = true;

  BannerAd? _banner;
  bool _adReady = false;
  InterstitialAd? _interstitialAd;

  final _cats = [
    {'name': 'राशन / ग्रॉसरी', 'icon': Icons.shopping_basket},
    {'name': 'खाना / होटल', 'icon': Icons.restaurant},
    {'name': 'पेट्रोल / यात्रा', 'icon': Icons.directions_car},
    {'name': 'बिल / रिचार्ज', 'icon': Icons.receipt_long},
    {'name': 'शॉपिंग / कपड़े', 'icon': Icons.shopping_bag},
    {'name': 'कमाई / सैलरी', 'icon': Icons.account_balance_wallet},
    {'name': 'अन्य खर्च', 'icon': Icons.category},
  ];
  final _modes = ['UPI / ऑनलाइन', 'नकद (Cash)', 'बैंक / कार्ड'];

  String tr(String key) => appStrings[_lang]?[key] ?? appStrings['hi']![key]!;

  @override
  void initState() {
    super.initState();
    _load();
    _initAd();
    _loadInterstitialAd();
  }

  void _initAd() {
    _banner = BannerAd(
      adUnitId: 'ca-app-pub-8588358418138615/8714800160',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _adReady = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      // Google Test Interstitial Ad Unit ID (Safe for Play Console review; replace with your real Interstitial ID once live)
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _banner?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('expenses_data');
    final savedLang = p.getString('app_lang') ?? 'hi';
    final rem = p.getBool('daily_reminders') ?? true;
    setState(() {
      _lang = savedLang;
      _remindersEnabled = rem;
      if (s != null) {
        _list = List>.from(json.decode(s)).map((m) {
          m['type'] = m['type'] ?? 'EXPENSE';
          m['cat'] = m['cat'] ?? m['category'] ?? 'अन्य खर्च';
          m['mode'] = m['mode'] ?? m['paymentMode'] ?? 'नकद (Cash)';
          return m;
        }).toList();
      }
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('expenses_data', json.encode(_list));
  }

  Future<void> _changeLang(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('app_lang', code);
    setState(() => _lang = code);
  }

  Future<void> _toggleReminders() async {
    final p = await SharedPreferences.getInstance();
    final nextVal = !_remindersEnabled;
    await p.setBool('daily_reminders', nextVal);
    setState(() => _remindersEnabled = nextVal);

    if (nextVal) {
      await scheduleDailyReminders();
    } else {
      await flutterLocalNotificationsPlugin.cancelAll();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nextVal ? tr('reminder_on') : tr('reminder_off')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLanguageSheet() {
    final langs = [
      {'code': 'hi', 'name': 'हिन्दी (Hindi)'},
      {'code': 'en', 'name': 'English'},
      {'code': 'ur', 'name': 'اردو (Urdu)'},
      {'code': 'mr', 'name': 'मराठी (Marathi)'},
      {'code': 'gu', 'name': 'ગુજરાતી (Gujarati)'},
      {'code': 'bn', 'name': 'বাংলা (Bengali)'},
      {'code': 'ta', 'name': 'தமிழ் (Tamil)'},
      {'code': 'te', 'name': 'తెలుగు (Telugu)'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('select_lang'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...langs.map((l) => ListTile(
                  title: Text(l['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: _lang == l['code']
                      ? const Icon(Icons.check_circle, color: Color(0xFF0F766E))
                      : null,
                  onTap: () {
                    _changeLang(l['code']!);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _onExportPdfPressed() {
    if (_list.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('no_data_pdf'))));
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
          _generateAndSharePdf();
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          _loadInterstitialAd();
          _generateAndSharePdf();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      _loadInterstitialAd();
      _generateAndSharePdf();
    }
  }

  Future<void> _generateAndSharePdf() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0F766E'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Rz Kharch Diary - Statement',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Text('Total Income: Rs. ${_inc.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        color: PdfColors.green800,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('Total Expense: Rs. ${_exp.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        color: PdfColors.red800,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('Balance: Rs. ${(_inc - _exp).toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromHex('#0F766E')),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Date', 'Title', 'Category', 'Mode', 'Type', 'Amount'],
              data: _list.map((item) {
                return [
                  item['date'].toString(),
                  item['title'].toString(),
                  item['cat'].toString(),
                  item['mode'].toString(),
                  item['type'].toString(),
                  'Rs. ${item['amount']}',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await
