import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../state/app_state.dart';
import '../models/position.dart';
import '../widgets/primary_button.dart';

class InputFormScreen extends StatefulWidget {
  const InputFormScreen({super.key});
  static const route = '/input';

  @override
  State<InputFormScreen> createState() => _InputFormScreenState();
}

class _InputFormScreenState extends State<InputFormScreen> {
  final _symbolCtl = TextEditingController();
  final _qtyCtl = TextEditingController();
  final _avgCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _yieldCtl = TextEditingController();
  final _divGrowCtl = TextEditingController();
  final _priceGrowCtl = TextEditingController();

  StockPosition? _editing; // 편집 모드 대상
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchDetail(String ticker) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
      final res = await http.get(Uri.parse('$baseUrl/api/stock/detail?ticker=$ticker'));
      final data = jsonDecode(res.body);

      _priceCtl.text = (data['data'][0]['last_close_price'] as num).toStringAsFixed(2);
      _yieldCtl.text = (data['data'][0]['dividend_yield'] as num).toStringAsFixed(2);
    } catch (_) {
      _showError('미국 시장에 상장된 종목만 가능합니다.');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    // 네비게이션 인자로 StockPosition이 오면 편집 모드로 전환
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is StockPosition) {
      _editing = arg;
      _symbolCtl.text = arg.symbol;
      _qtyCtl.text = arg.quantity.toString();
      _avgCtl.text = arg.avgCost.toStringAsFixed(2);
      _priceCtl.text = arg.currentPrice.toStringAsFixed(2);
      _yieldCtl.text = (arg.dividendYield * 100).toStringAsFixed(2);
      _divGrowCtl.text = (arg.dividendGrowthRate * 100).toStringAsFixed(2);
      _priceGrowCtl.text = (arg.priceGrowthRate * 100).toStringAsFixed(2);
    }

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_editing == null ? '주식 추가' : '주식 수정'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('포지션 정보'),

              Text('종목명', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _symbolCtl.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final input = textEditingValue.text;
                  if (input.length < 2) {
                    return const Iterable<String>.empty();
                  }

                  final list = context.read<AppState>().tickerOptions;
                  return list.where((t) => t.startsWith(input.toUpperCase()));
                },
                onSelected: (sel) {
                  _symbolCtl.text = sel;
                  _fetchDetail(sel);
                },
                fieldViewBuilder: (_, ctl, focus, onFieldSubmitted) => CupertinoTextField(
                  controller: ctl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z\.X]'))
                  ],
                  focusNode: focus,
                  placeholder: '종목명',
                  onChanged: (text) {
                    final upper = text.toUpperCase();
                    if (text != upper) {
                      ctl.value = ctl.value.copyWith(
                        text: upper,
                        selection: TextSelection.collapsed(offset: upper.length),
                      );
                    }
                  },
                  onSubmitted: (text) {
                    onFieldSubmitted();
                    if (text.isNotEmpty) {
                      _symbolCtl.text = text;
                      _fetchDetail(text);
                    }
                  },
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),


              _field(label: '보유 수량', controller: _qtyCtl, isNumber: true),
              _field(label: '평균 단가 (USD)', controller: _avgCtl, isNumber: true),

              _sectionTitle('배당·주가 데이터'),
              _sectionFieldWithHelper(label: '현재 주가 (USD)', controller: _priceCtl, isNumber: true, helper: '* 티커 입력 시 자동 채움(전일 종가)', enabled: false,),
              _sectionFieldWithHelper(label: '배당률 (%)', controller: _yieldCtl, isNumber: true, helper: '* 티커 입력 시 자동 채움', enabled: false,),

              _field(label: '배당 성장률 (%/년)', controller: _divGrowCtl, isNumber: true),
              _field(label: '주가 상승률 (%/년)', controller: _priceGrowCtl, isNumber: true),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: _editing == null ? '저장' : '수정 완료',
                  onPressed: _onSubmit,
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 공용 필드 위젯 ──
  Widget _field({
    required String label,
    required TextEditingController controller,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: controller,
            placeholder: label,
            keyboardType:
                isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

Widget _sectionFieldWithHelper({
  required String label,
  required TextEditingController controller,
  bool isNumber = false,
  required String helper,
  bool enabled = true,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(helper, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
          ],
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          enabled: enabled,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    ),
  );
}

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: CupertinoColors.systemGrey),
        ),
      );

  // ── 저장/수정 처리 ──
  void _onSubmit() {
    final app = context.read<AppState>();
    final symbol = _symbolCtl.text.trim().toUpperCase();
    final tickers = app.tickerOptions;

    if (symbol.isEmpty) {
      _showError('티커를 선택해주세요.');
      return;
    }
    if (!tickers.contains(symbol)) {
      _showError('유효한 티커를 선택해주세요.');
      return;
    }

    final qtyText = _qtyCtl.text.trim();
    if (qtyText.isEmpty) {
      _showError('보유 수량을 입력해주세요.');
      return;
    }
    final qty = double.tryParse(qtyText);
    if (qty == null || qty <= 0) {
      _showError('보유 수량은 0보다 큰 숫자여야 합니다.');
      return;
    }

    final avgText = _avgCtl.text.trim();
    if (avgText.isEmpty) {
      _showError('평균 단가를 입력해주세요.');
      return;
    }
    final avg = double.tryParse(avgText);
    if (avg == null || avg < 0) {
      _showError('평균 단가는 0 이상이어야 합니다.');
      return;
    }

    final priceText = _priceCtl.text.trim();
    if (priceText.isEmpty) {
      _showError('현재 주가를 입력해주세요.');
      return;
    }
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showError('현재 주가는 0보다 큰 숫자여야 합니다.');
      return;
    }

    final yieldText = _yieldCtl.text.trim();
    if (yieldText.isEmpty) {
      _showError('배당률을 입력해주세요.');
      return;
    }
    final yieldPct = double.tryParse(yieldText);
    if (yieldPct == null || yieldPct <= 0) {
      _showError('배당률은 0보다 큰 숫자여야 합니다.');
      return;
    }

    final divGrowText = _divGrowCtl.text.trim();
    if (divGrowText.isEmpty) {
      _showError('배당 성장률을 입력해주세요.');
      return;
    }
    final divGrow = double.tryParse(divGrowText) ?? 0;

    final priceGrowText = _priceGrowCtl.text.trim();
    if (priceGrowText.isEmpty) {
      _showError('주가 상승률을 입력해주세요.');
      return;
    }
    final priceGrow = double.tryParse(priceGrowText) ?? 0;
    final alloc = _editing?.allocationRate ?? (app.positions.isEmpty ? 1.0 : 0.0);

    final newPosition = StockPosition(
      symbol: symbol,
      quantity: qty,
      avgCost: avg,
      currentPrice: price,
      dividendYield: yieldPct / 100,
      dividendGrowthRate: divGrow / 100,
      priceGrowthRate: priceGrow / 100,
      allocationRate: alloc,
    );

    if (_editing == null) {
      app.addPosition(newPosition);
    } else {
      app.replacePosition(_editing!, newPosition);
    }
    Navigator.pop(context);
  }

  void _showError(String msg) => showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('입력 오류'),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(child: const Text('확인'), onPressed: () => Navigator.pop(context)),
          ],
        ),
      );

  @override
  void dispose() {
    for (final c in [
      _symbolCtl,
      _qtyCtl,
      _avgCtl,
      _priceCtl,
      _yieldCtl,
      _divGrowCtl,
      _priceGrowCtl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}