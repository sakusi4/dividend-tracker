import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/position.dart';

class AppState extends ChangeNotifier {
  static const _storageKey = 'portfolio_data';

  double targetPerMonth = 300;
  double monthlyContribution = 500;
  final List<StockPosition> _positions = [];
  bool _ready = false; // 데이터 로딩 완료 플래그
  bool get ready => _ready;

  AppState() {
    _load(); // 생성과 동시에 SharedPreferences 로드
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

  // ── Persistence ──
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      final Map<String, dynamic> obj = jsonDecode(jsonStr);
      targetPerMonth = (obj['targetPerMonth'] as num).toDouble();
      monthlyContribution = (obj['monthlyContribution'] as num).toDouble();
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
      'positions': _positions.map((e) => e.toJson()).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(obj));
    notifyListeners();
  }
}