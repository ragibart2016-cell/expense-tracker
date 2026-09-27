import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MaterialApp(
    title: 'Kharch Diary',
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
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
                    BoxShadow(color: const Color(0xFF0F766E).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))
                  ],
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 16),
              const Text('Kharch Diary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
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
  List<Map<String, dynamic>> _list = [];
  String _query = '';
  String _filter = 'ALL';
  BannerAd? _banner;
  bool _adReady = false;

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

  @override
  void initState() {
    super.initState();
    _load();
    _initAd();
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

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('expenses_data');
    if (s != null) {
      setState(() {
        _list = List<Map<String, dynamic>>.from(json.decode(s)).map((m) {
          m['type'] = m['type'] ?? 'EXPENSE';
          m['cat'] = m['cat'] ?? m['category'] ?? 'अन्य खर्च';
          m['mode'] = m['mode'] ?? m['paymentMode'] ?? 'नकद (Cash)';
          return m;
        }).toList();
      });
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('expenses_data', json.encode(_list));
  }

  double get _inc => _list.where((e) => e['type'] == 'INCOME').fold(0.0, (s, e) => s + (e['amount'] as num).toDouble());
  double get _exp => _list.where((e) => e['type'] == 'EXPENSE').fold(0.0, (s, e) => s + (e['amount'] as num).toDouble());

  IconData _icon(String c) => (_cats.firstWhere((e) => e['name'] == c, orElse: () => _cats.last)['icon'] as IconData);

  void _showDetails(Map<String, dynamic> item) {
    final isExp = item['type'] == 'EXPENSE';
    final amount = (item['amount'] as num).toDouble();
    final title = item['title'] ?? '';
    final cat = item['cat'] ?? 'अन्य खर्च';
    final mode = item['mode'] ?? 'नकद (Cash)';
    final date = item['date'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('लेन-देन का पूरा ब्योरा', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isExp ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${isExp ? "-" : "+"}₹${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isExp ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isExp ? 'खर्च (Expense)' : 'कमाई (Income)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isExp ? Colors.red.shade800 : Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded, color: Color(0xFF0F766E), size: 28),
              title: const Text('विवरण / नाम', style: TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: Icon(_icon(cat), color: const Color(0xFF0F766E), size: 26),
              title: const Text('कैटिगरी', style: TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: Text(cat, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.payment_rounded, color: Color(0xFF0F766E), size: 26),
              title: const Text('पेमेंट माध्यम', style: TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: Text(mode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded, color: Color(0xFF0F766E), size: 24),
              title: const Text('तारीख और समय', style: TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: Text(date, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('इस लेन-देन को हटाएँ (Delete)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() => _list.removeWhere((x) => x['id'] == item['id']));
                _save();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAdd() {
    final tC = TextEditingController();
    final aC = TextEditingController();
    String type = 'EXPENSE';
    String cat = _cats.first['name'] as String;
    String mode = _modes.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, top: 16, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('नया लेन-देन', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('खर्च (Expense)')),
                      selected: type == 'EXPENSE',
                      selectedColor: Colors.red.shade100,
                      onSelected: (_) => setM(() => type = 'EXPENSE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('कमाई (Income)')),
                      selected: type == 'INCOME',
                      selectedColor: Colors.green.shade100,
                      onSelected: (_) => setM(() => type = 'INCOME'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: aC,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'रकम (₹) *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tC,
                decoration: const InputDecoration(labelText: 'विवरण / नाम (खाली छोड़ने पर कैटिगरी का नाम रहेगा)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: cat,
                decoration: const InputDecoration(labelText: 'कैटिगरी', border: OutlineInputBorder()),
                items: _cats.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name'] as String))).toList(),
                onChanged: (v) => setM(() => cat = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(labelText: 'पेमेंट मोड', border: OutlineInputBorder()),
                items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setM(() => mode = v!),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: type == 'EXPENSE' ? Colors.red.shade700 : const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final a = double.tryParse(aC.text.trim());
                    if (a == null || a <= 0) return;
                    String t = tC.text.trim();
                    if (t.isEmpty) t = cat;

                    setState(() {
                      _list.insert(0, {
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'title': t,
                        'amount': a,
                        'type': type,
                        'cat': cat,
                        'mode': mode,
                        'date': DateFormat('dd MMM, hh:mm a').format(DateTime.now()),
                      });
                    });
                    _save();
                    Navigator.pop(ctx);
                  },
                  child: const Text('सेव करें', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _list.where((e) {
      final mF = _filter == 'ALL' || e['type'] == _filter;
      final mS = e['title'].toString().toLowerCase().contains(_query.toLowerCase()) ||
          e['cat'].toString().toLowerCase().contains(_query.toLowerCase());
      return mF && mS;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text('Kharch Diary', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('बचा हुआ बैलेंस (Net Balance)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('₹${(_inc - _exp).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 14), Text(' कमाई', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                          Text('₹${_inc.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [Icon(Icons.arrow_upward, color: Colors.redAccent, size: 14), Text(' खर्च', style: TextStyle(color: Colors.white70, fontSize: 11))]),
                          Text('₹${_exp.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'सर्च करें...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                ChoiceChip(label: const Text('सभी'), selected: _filter == 'ALL', onSelected: (_) => setState(() => _filter = 'ALL')),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('खर्च'), selected: _filter == 'EXPENSE', selectedColor: Colors.red.shade100, onSelected: (_) => setState(() => _filter = 'EXPENSE')),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('कमाई'), selected: _filter == 'INCOME', selectedColor: Colors.green.shade100, onSelected: (_) => setState(() => _filter = 'INCOME')),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('कोई लेन-देन नहीं मिला!\n+ दबाकर जोड़ें।', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      final isExp = item['type'] == 'EXPENSE';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: () => _showDetails(item),
                          leading: CircleAvatar(
                            backgroundColor: isExp ? Colors.red.shade50 : Colors.green.shade50,
                            foregroundColor: isExp ? Colors.red.shade700 : Colors.green.shade700,
                            child: Icon(_icon(item['cat'])),
                          ),
                          title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item['date']} • ${item['mode']}', style: const TextStyle(fontSize: 11)),
                          trailing: Row(
                      
