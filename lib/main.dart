import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fast Startup: Initialize MobileAds in the background without blocking the UI
  MobileAds.instance.initialize();
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kharch Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const ExpenseHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExpenseHomeScreen extends StatefulWidget {
  const ExpenseHomeScreen({super.key});

  @override
  State<ExpenseHomeScreen> createState() => _ExpenseHomeScreenState();
}

class _ExpenseHomeScreenState extends State<ExpenseHomeScreen> {
  List<Map<String, dynamic>> _transactions = [];
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // ALL, EXPENSE, INCOME

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedType = 'EXPENSE'; // EXPENSE or INCOME
  String _selectedCategory = 'राशन / ग्रॉसरी';
  String _selectedPaymentMode = 'UPI / ऑनलाइन';

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  final String _adUnitId = 'ca-app-pub-6588358418138815/8714606100';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'राशन / ग्रॉसरी', 'icon': Icons.shopping_basket},
    {'name': 'खाना / होटल', 'icon': Icons.restaurant},
    {'name': 'पेट्रोल / यात्रा', 'icon': Icons.directions_car},
    {'name': 'बिल / रिचार्ज', 'icon': Icons.receipt_long},
    {'name': 'शॉपिंग / कपड़े', 'icon': Icons.shopping_bag},
    {'name': 'सैलरी / कमाई', 'icon': Icons.account_balance_wallet},
    {'name': 'अन्य खर्च', 'icon': Icons.category},
  ];

  final List<String> _paymentModes = ['UPI / ऑनलाइन', 'नकद (Cash)', 'बैंक / कार्ड'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _initBannerAd();
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isBannerAdLoaded = true),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString('expenses_data');
    if (dataString != null) {
      final List<dynamic> decoded = json.decode(dataString);
      setState(() {
        _transactions = decoded.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['type'] = map['type'] ?? 'EXPENSE';
          map['category'] = map['category'] ?? 'अन्य खर्च';
          map['paymentMode'] = map['paymentMode'] ?? 'नकद (Cash)';
          return map;
        }).toList();
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses_data', json.encode(_transactions));
  }

  void _addTransaction() {
    final String title = _titleController.text.trim();
    final double? amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty || amount == null || amount <= 0) return;

    final newEntry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'amount': amount,
      'type': _selectedType,
      'category': _selectedCategory,
      'paymentMode': _selectedPaymentMode,
      'date': DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
    };

    setState(() {
      _transactions.insert(0, newEntry);
    });

    _saveData();
    _titleController.clear();
    _amountController.clear();
    Navigator.of(context).pop();
  }

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((item) => item['id'] == id);
    });
    _saveData();
  }

  double get _totalIncome {
    return _transactions
        .where((item) => item['type'] == 'INCOME')
        .fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
  }

  double get _totalExpense {
    return _transactions
        .where((item) => item['type'] == 'EXPENSE')
        .fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
  }

  double get _netBalance => _totalIncome - _totalExpense;

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((item) {
      final matchesFilter = _selectedFilter == 'ALL' || item['type'] == _selectedFilter;
      final matchesSearch = item['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  IconData _getCategoryIcon(String category) {
    final match = _categories.firstWhere(
      (cat) => cat['name'] == category,
      orElse: () => {'icon': Icons.currency_rupee},
    );
    return match['icon'] as IconData;
  }

  void _showAddDialog() {
    _selectedType = 'EXPENSE';
    _selectedCategory = 'राशन / ग्रॉसरी';
    _selectedPaymentMode = 'UPI / ऑनलाइन';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('नया लेन-देन जोड़ें', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              // Segmented Type: Expense or Income
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('खर्च (Expense)')),
                      selected: _selectedType == 'EXPENSE',
                      selectedColor: Colors.red.shade100,
                      labelStyle: TextStyle(
                        color: _selectedType == 'EXPENSE' ? Colors.red.shade900 : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) => setModalState(() => _selectedType = 'EXPENSE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('कमाई (Income)')),
                      selected: _selectedType == 'INCOME',
                      selectedColor: Colors.green.shade100,
                      labelStyle: TextStyle(
                        color: _selectedType == 'INCOME' ? Colors.green.shade900 : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) => setModalState(() => _selectedType = 'INCOME'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'रकम (Amount)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'विवरण / नाम (उदा. दूध, सब्ज़ी, सैलरी)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'कैटिगरी',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['name'] as String,
                    child: Row(
                      children: [
                        Icon(c['icon'] as IconData, size: 20, color: const Color(0xFF0F766E)),
                        const SizedBox(width: 8),
                        Text(c['name'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setModalState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMode,
                decoration: InputDecoration(
                  labelText: 'पेमेंट मोड',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _paymentModes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setModalState(() => _selectedPaymentMode = val!),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _addTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == 'EXPENSE' ? Colors.red.shade700 : const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('सुरक्षित सेव करें', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kharch Diary', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Total Balance Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              children: [
                const Text('कुल बचा हुआ बैलेंस (Net Balance)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '₹${_netBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _netBalance < 0 ? Colors.amberAccent : Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16),
                                SizedBox(width: 4),
                                Text('कमाई (Income)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('₹${_totalIncome.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.arrow_upward, color: Colors.redAccent, size: 16),
                                SizedBox(width: 4),
                                Text('खर्च (Expense)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('₹${_totalExpense.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search & Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'सर्च करें (उदा. राशन, चाय)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('सभी'),
                      selected: _selectedFilter == 'ALL',
                      onSelected: (val) => setState(() => _selectedFilter = 'ALL'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('सिर्फ खर्च'),
                      selected: _selectedFilter == 'EXPENSE',
                      selectedColor: Colors.red.shade100,
                      onSelected: (val) => setState(() => _selectedFilter = 'EXPENSE'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('सिर्फ कमाई'),
                      selected: _selectedFilter == 'INCOME',
                      selectedColor: Colors.green.shade100,
                      onSelected: (val) => setState(() => _selectedFilter = 'INCOME'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Transaction List
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'कोई लेन-देन नहीं मिला!\nनीचे + बटन दबाकर जोड़ें।',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (ctx, index) {
                      final item = list[index];
                      final isExpense = item['type'] == 'EXPENSE';
                      final category = item['category'] ?? 'अन्य खर्च';
                      final mode = item['paymentMode'] ?? 'नकद (Cash)';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isExpense ? Colors.red.shade50 : Colors.green.shade50,
                            foregroundColor: isExpense ? Colors.red.shade700 : Colors.green.shade700,
                            child: Icon(_getCategoryIcon(category)),
                          ),
                          title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(
                            '${item['date']} • $mode',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
   
