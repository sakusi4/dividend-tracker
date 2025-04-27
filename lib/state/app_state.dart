import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/position.dart';

class AppState extends ChangeNotifier {
  static const _storageKey = 'portfolio_data';

  double targetPerMonth = 0;
  double monthlyContribution = 0;
  bool reinvestDividends = true; // 배당 재투자 여부
  final List<StockPosition> _positions = [];
  bool _ready = false; // 데이터 로딩 완료 플래그
  bool get ready => _ready;

  List<String> tickerOptions = [];

  AppState() {
    _load().then((_) {
      _fetchAllTickers();
      _updatePortfolioPrices();
    });
  }

  List<StockPosition> get positions => List.unmodifiable(_positions);

  // ── CRUD ──
  void addPosition(StockPosition p) {
    _positions.add(p);
    _save();
  }

  void updateGoal(double v) {
    targetPerMonth = v;
    _save();
  }

  void updateMonthlyContribution(double v) {
    monthlyContribution = v;
    _save();
  }

  void updateReinvestDividends(bool v) {
    reinvestDividends = v;
    _save();
  }

  // ── 삭제 ──
  void removePosition(StockPosition p) {
    _positions.remove(p);
    _save();          // SharedPreferences 동기화
  }

  // ── 편집(교체) ──
  void replacePosition(StockPosition oldP, StockPosition newP) {
    final idx = _positions.indexOf(oldP);
    if (idx != -1) {
      _positions[idx] = newP;
      _save();
    }
  }

  void updateAllocation(StockPosition p, double rate) {
    p.allocationRate = rate;
    _save();
  }

  Future<void> _fetchAllTickers() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    debugPrint(baseUrl);

    final res = await http.get(Uri.parse('$baseUrl/api/stock'));
    final data = jsonDecode(res.body)['data'] as List;
    tickerOptions = data.map((e) => e['ticker'] as String).toList();
    notifyListeners();
  }

  Future<void> _updatePortfolioPrices() async {
    if (_positions.isEmpty) return;
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';

    final tickers = _positions.map((p) => p.symbol).join(',');
    final res = await http.get(Uri.parse('$baseUrl/api/stock/detail?ticker=$tickers'));
    final list = jsonDecode(res.body)['data'] as List;
    for (final item in list) {
      final pos = _positions.firstWhere((p) => p.symbol == item['ticker']);
      pos.currentPrice = (item['last_close_price'] as num).toDouble();
      pos.dividendYield = (item['dividend_yield'] as num).toDouble() / 100;
    }

    notifyListeners();
    _save();
  }

  // ── Persistence ──
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      final Map<String, dynamic> obj = jsonDecode(jsonStr);
      targetPerMonth = (obj['targetPerMonth'] as num).toDouble();
      monthlyContribution = (obj['monthlyContribution'] as num).toDouble();
      reinvestDividends = obj['reinvestDividends'] as bool? ?? true;
      _positions
        ..clear()
        ..addAll((obj['positions'] as List)
            .map((e) => StockPosition.fromJson(e)));
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final obj = {
      'targetPerMonth': targetPerMonth,
      'monthlyContribution': monthlyContribution,
      'reinvestDividends': reinvestDividends,
      'positions': _positions.map((e) => e.toJson()).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(obj));
    notifyListeners();
  }
}