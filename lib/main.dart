import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          primary: const Color(0xFF0F766E),
        ),
        useMaterial3: true,
      ),
      home: const ExpenseHomePage(),
    );
  }
}

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory ExpenseItem.fromMap(Map<String, dynamic> map) => ExpenseItem(
        id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: map['title'] ?? '',
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] ?? 'Other',
        date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      );
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  List<ExpenseItem> _expenses = [];
  bool _isLoading = true;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = 'Food (खाना)';
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food (खाना)', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Travel (किराया/पेट्रोल)', 'icon': Icons.directions_bus, 'color': Colors.blue},
    {'name': 'Bills (बिल/रिचार्ज)', 'icon': Icons.receipt_long, 'color': Colors.purple},
    {'name': 'Shopping (खरीदारी)', 'icon': Icons.shopping_bag, 'color': Colors.pink},
    {'name': 'Health (दवा)', 'icon': Icons.medical_services, 'color': Colors.red},
    {'name': 'Other (अन्य)', 'icon': Icons.more_horiz, 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _initBannerAd();
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawData = prefs.getString('user_expenses');
    if (rawData != null) {
      try {
        final List decoded = jsonDecode(rawData);
        _expenses = decoded.map((e) => ExpenseItem.fromMap(e)).toList();
        _expenses.sort((a, b) => b.date.compareTo(a.date));
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_expenses.map((e) => e.toMap()).toList());
    await prefs.setString('user_expenses', encoded);
  }

  void _addExpense() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty || amount == null || amount <= 0) return;

    final newExpense = ExpenseItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
    );

    setState(() {
      _expenses.insert(0, newExpense);
      _expenses.sort((a, b) => b.date.compareTo(a.date));
    });

    _saveExpenses();
    _titleController.clear();
    _amountController.clear();
    Navigator.of(context).pop();
  }

  void _deleteExpense(String id) {
    setState(() => _expenses.removeWhere((item) => item.id == id));
    _saveExpenses();
  }

  double get _totalExpense => _expenses.fold(0.0, (sum, item) => sum + item.amount);

  void _openAddModal() {
    _titleController.clear();
    _amountController.clear();
    _selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('नया खर्च जोड़ें', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'खर्च का नाम', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'राशि (₹)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name']))).toList(),
                onChanged: (val) => setModalState(() => _selectedCategory = val!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _addExpense,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                child: const Text('सेव करें'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('कुल खर्च', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text('₹${_totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: _expenses.isEmpty
                      ? const Center(child: Text('कोई खर्च नहीं है। नीचे + दबाएं।'))
                      : ListView.builder(
                          itemCount: _expenses.length,
                          itemBuilder: (ctx, i) {
                            final item = _expenses[i];
                            return ListTile(
                              title: Text(item.title),
                              subtitle: Text(item.category),
                              trailing: Text('₹${item.amount}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                              onLongPress: () => _deleteExpense(item.id),
                            );
                          },
                        ),
                ),
                if (_isBannerAdLoaded && _bannerAd != null)
                  Container(
                    alignment: Alignment.center,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
              ],
            ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _isBannerAdLoaded ? 50.0 : 0.0),
        child: FloatingActionButton(
          onPressed: _openAddModal,
          backgroundColor: const Color(0xFF0F766E),
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
