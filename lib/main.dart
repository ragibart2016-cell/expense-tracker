import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await _initNotifications();
  runApp(const RzKharchDiaryApp());
}

Future<void> _initNotifications() async {
  tz.initializeTimeZones();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();

  await _scheduleDailyReminders();
}

Future<void> _scheduleDailyReminders() async {
  await flutterLocalNotificationsPlugin.cancelAll();

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'daily_expense_reminder',
    'Daily Expense Reminders',
    channelDescription: 'Reminds you morning and evening to log expenses',
    importance: Importance.high,
    priority: Priority.high,
  );
  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    101,
    'Good Morning! ☀️',
    'Start your day organized — log your planned budget or morning expenses in Rz Kharch Diary.',
    _nextInstanceOfTime(9, 0),
    platformDetails,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    102,
    'Evening Kharch Check 📒',
    'Don\'t forget to record today\'s income & expenses before sleeping!',
    _nextInstanceOfTime(20, 30),
    platformDetails,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final now = DateTime.now();
  var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return tz.TZDateTime.from(scheduled, tz.local);
}

class RzKharchDiaryApp extends StatelessWidget {
  const RzKharchDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rz Kharch Diary',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F6F8),
      ),
      home: const HomeScreen(),
    );
  }
}

class Entry {
  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final String category;
  final DateTime date;

  Entry({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'isIncome': isIncome,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'],
        title: j['title'],
        amount: (j['amount'] as num).toDouble(),
        isIncome: j['isIncome'],
        category: j['category'] ?? 'General',
        date: DateTime.parse(j['date']),
      );
}

const Map<String, Map<String, String>> appStrings = {
  'en': {
    'app_name': 'Rz Kharch Diary',
    'balance': 'Available Balance',
    'income': 'Income',
    'expense': 'Expense',
    'add_entry': 'Add Entry',
    'edit_entry': 'Edit Entry',
    'title_hint': 'Title (e.g., Groceries, Salary)',
    'amount_hint': 'Amount (₹)',
    'save': 'Save Entry',
    'no_entries': 'No entries yet. Tap + to add!',
    'export_pdf': 'Export PDF Report',
    'privacy': 'Privacy Policy',
    'lang_name': 'English',
  },
  'hi': {
    'app_name': 'Rz खर्च डायरी',
    'balance': 'कुल शेष राशि',
    'income': 'आमदनी',
    'expense': 'खर्च',
    'add_entry': 'नया हिसाब जोड़ें',
    'edit_entry': 'हिसाब बदलें',
    'title_hint': 'विवरण (जैसे: राशन, सैलरी)',
    'amount_hint': 'रकम (₹)',
    'save': 'सेव करें',
    'no_entries': 'अभी कोई हिसाब नहीं है। + दबाकर जोड़ें!',
    'export_pdf': 'PDF रिपोर्ट डाउनलोड करें',
    'privacy': 'प्राइवेसी पॉलिसी',
    'lang_name': 'हिंदी (Hindi)',
  },
  'ur': {
    'app_name': 'Rz خرچ ڈائری',
    'balance': 'بقیہ بیلنس',
    'income': 'آمدنی',
    'expense': 'خرچ',
    'add_entry': 'نیا اندراج کریں',
    'edit_entry': 'اندراج تبدیل کریں',
    'title_hint': 'تفصیل (مثلاً راشن، تنخواہ)',
    'amount_hint': 'رقم (₹)',
    'save': 'محفوظ کریں',
    'no_entries': 'ابھی کوئی اندراج نہیں ہے۔ + دبائیں!',
    'export_pdf': 'PDF رپورٹ ڈاؤن لوڈ کریں',
    'privacy': 'پرائیویسی پالیسی',
    'lang_name': 'اردو (Urdu)',
  },
  'bn': {
    'app_name': 'Rz খরচ ডায়েরি',
    'balance': 'বর্তমান ব্যালেন্স',
    'income': 'আয়',
    'expense': 'ব্যয়',
    'add_entry': 'নতুন হিসাব যোগ করুন',
    'edit_entry': 'হিসাব সম্পাদনা করুন',
    'title_hint': 'বিবরণ (যেমন: বাজার, বেতন)',
    'amount_hint': 'টাকার পরিমাণ (₹)',
    'save': 'সংরক্ষণ করুন',
    'no_entries': 'এখনো কোনো হিসাব নেই। + চাপুন!',
    'export_pdf': 'PDF রিপোর্ট ডাউনলোড',
    'privacy': 'গোপনীয়তা নীতি',
    'lang_name': 'বাংলা (Bengali)',
  },
  'mr': {
    'app_name': 'Rz खर्च डायरी',
    'balance': 'उपलब्ध शिल्लक',
    'income': 'उत्पन्न',
    'expense': 'खर्च',
    'add_entry': 'नवीन नोंद करा',
    'edit_entry': 'नोंद बदला',
    'title_hint': 'तपशील (उदा. किराणा, पगार)',
    'amount_hint': 'रक्कम (₹)',
    'save': 'जतन करा',
    'no_entries': 'अद्याप कोणतीही नोंद नाही. + दाबा!',
    'export_pdf': 'PDF अहवाल डाउनलोड करा',
    'privacy': 'गोपनीयता धोरण',
    'lang_name': 'मराठी (Marathi)',
  },
  'gu': {
    'app_name': 'Rz ખર્ચ ડાયરી',
    'balance': 'ઉપલબ્ધ બેલેન્સ',
    'income': 'આવક',
    'expense': 'ખર્ચ',
    'add_entry': 'નવી એન્ટ્રી ઉમેરો',
    'edit_entry': 'એન્ટ્રી સુધારો',
    'title_hint': 'વિગત (દા.ત. કરિયાણું, પગાર)',
    'amount_hint': 'રકમ (₹)',
    'save': 'સેવ કરો',
    'no_entries': 'હજુ સુધી કોઈ એન્ટ્રી નથી. + દબાવો!',
    'export_pdf': 'PDF રિપોર્ટ ડાઉનલોડ કરો',
    'privacy': 'પ્રાઇવસી પોલિસી',
    'lang_name': 'ગુજરાતી (Gujarati)',
  },
  'ta': {
    'app_name': 'Rz செலவு டைரி',
    'balance': 'மீதமுள்ள இருப்பு',
    'income': 'வருமானம்',
    'expense': 'செலவு',
    'add_entry': 'புதிய பதிவு சேர்',
    'edit_entry': 'பதிவை திருத்து',
    'title_hint': 'விவரம் (எ.கா. மளிகை, சம்பளம்)',
    'amount_hint': 'தொகை (₹)',
    'save': 'சேமி',
    'no_entries': 'பதிவுகள் இல்லை. + அழுத்தவும்!',
    'export_pdf': 'PDF அறிக்கை பதிவிறக்கு',
    'privacy': 'தனியுரிமைக் கொள்கை',
    'lang_name': 'தமிழ் (Tamil)',
  },
  'te': {
    'app_name': 'Rz ఖర్చు డైరీ',
    'balance': 'అందుబాటులో ఉన్న బ్యాలెన్స్',
    'income': 'ఆదాయం',
    'expense': 'ఖర్చు',
    'add_entry': 'కొత్త నమోదు జోడించండి',
    'edit_entry': 'నమోదు సవరించండి',
    'title_hint': 'వివరాలు (ఉదా. సరుకులు, జీతం)',
    'amount_hint': 'మొత్తం (₹)',
    'save': 'సేవ్ చేయండి',
    'no_entries': 'ఇంకా నమోదులు లేవు. + నొక్కండి!',
    'export_pdf': 'PDF నివేదిక డౌన్‌లోడ్',
    'privacy': 'గోప్యతా విధానం',
    'lang_name': 'తెలుగు (Telugu)',
  },
  'ar': {
    'app_name': 'Rz دفتر المصاريف',
    'balance': 'الرصيد المتاح',
    'income': 'الدخل',
    'expense': 'المصروفات',
    'add_entry': 'إضافة معاملة',
    'edit_entry': 'تعديل المعاملة',
    'title_hint': 'الوصف (مثل: بقالة، راتب)',
    'amount_hint': 'المبلغ (₹)',
    'save': 'حفظ',
    'no_entries': 'لا توجد معاملات بعد. اضغط + للإضافة!',
    'export_pdf': 'تصدير تقرير PDF',
    'privacy': 'سياسة الخصوصية',
    'lang_name': 'العربية (Arabic)',
  },
  'es': {
    'app_name': 'Rz Diario de Gastos',
    'balance': 'Saldo Disponible',
    'income': 'Ingresos',
    'expense': 'Gastos',
    'add_entry': 'Agregar Registro',
    'edit_entry': 'Editar Registro',
    'title_hint': 'Título (ej. Compras, Salario)',
    'amount_hint': 'Monto (₹)',
    'save': 'Guardar',
    'no_entries': 'Sin registros aún. ¡Toca + para agregar!',
    'export_pdf': 'Exportar Reporte PDF',
    'privacy': 'Política de Privacidad',
    'lang_name': 'Español (Spanish)',
  },
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Entry> _list = [];
  String _lang = 'en';
  String _filter = 'All';

  BannerAd? _bannerAd;
  bool _isBannerReady = false;
  InterstitialAd? _interstitialAd;

  final String _bannerAdUnitId = 'ca-app-pub-8588358418138615/9227319870';
  final String _interstitialAdUnitId = 'ca-app-pub-8588358418138615/1801235267';

  final List<String> _categories = [
    'General',
    'Food',
    'Travel',
    'Bills',
    'Shopping',
    'Salary',
    'Business',
    'Health'
  ];

  String t(String key) => appStrings[_lang]?[key] ?? appStrings['en']![key]!;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerReady = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          _interstitialAd = null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('entries_v2');
    final savedLang = p.getString('app_lang') ?? 'en';
    setState(() {
      _lang = savedLang;
      if (s != null) {
        _list = List>.from(json.decode(s))
            .map((e) => Entry.fromJson(e))
            .toList();
      }
    });
  }

  Future<void> _saveData() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'entries_v2', json.encode(_list.map((e) => e.toJson()).toList()));
  }

  Future<void> _changeLanguage(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('app_lang', code);
    setState(() => _lang = code);
  }

  double get _inc =>
      _list.where((e) => e.isIncome).fold(0.0, (a, b) => a + b.amount);
  double get _exp =>
      _list.where((e) => !e.isIncome).fold(0.0, (a, b) => a + b.amount);

  List<Entry> get _filteredList {
    if (_filter == 'Income') return _list.where((e) => e.isIncome).toList();
    if (_filter == 'Expense') return _list.where((e) => !e.isIncome).toList();
    return _list;
  }

  void _onExportPdfPressed() {
    if (_list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries available to export!')),
      );
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
          _generateAndSharePdf();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _loadInterstitialAd();
          _generateAndSharePdf();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      _generateAndSharePdf();
      _loadInterstitialAd();
    }
  }

  Future<void> _generateAndSharePdf() async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Rz Kharch Diary - Statement',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
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
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Title', 'Category', 'Type', 'Amount (Rs.)'],
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.teal800),
            cellAlignment: pw.Alignment.centerLeft,
            data: _list.map((e) {
              return [
                DateFormat('dd/MM/yyyy').format(e.date),
                e.title,
                e.category,
                e.isIncome ? 'Income' : 'Expense',
                '${e.isIncome ? '+' : '-'} ${e.amount.toStringAsFixed(2)}',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'Rz_Kharch_Diary_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  void _openLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: appStrings.entries.map((entry) {
          final code = entry.key;
          final name = entry.value['lang_name']!;
          return ListTile(
            leading: Icon(
              _lang == code ? Icons.radio_button_checked : Icons.radio_button_off,
              color: const Color(0xFF0F766E),
            ),
            title: Text(name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              _changeLanguage(code);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _openForm({Entry? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final amtCtrl = TextEditingController(
        text: existing != null ? existing.amount.toStringAsFixed(0) : '');
    bool isIncome = existing?.isIncome ?? false;
    String selectedCat = existing?.category ?? 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? t('add_entry') : t('edit_entry'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(t('expense'))),
                      selected: !isIncome,
                      selectedColor: Colors.red.shade100,
                      onSelected: (_) => setModalState(() => isIncome = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(t('income'))),
                      selected: isIncome,
                      selectedColor: Colors.green.shade100,
                      onSelected: (_) => setModalState(() => isIncome = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: t('title_hint'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: t('amount_hint'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categories.contains(selectedCat)
                    ? selectedCat
                    : 'General',
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items
