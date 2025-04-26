import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/position.dart';
import 'input_form_screen.dart';
import 'result_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({Key? key}) : super(key: key);
  static const route = '/portfolio';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('My Portfolio'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => Navigator.pushNamed(context, InputFormScreen.route),
        ),
      ),
      child: Stack(children: [const _Body(), const _CalcButton()]),
    );
  }
}


class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final usd2 = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final pct1 = NumberFormat.decimalPercentPattern(
      locale: 'en',
      decimalDigits: 1,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          const _SectionTitle('투자 설정'),
          const _InvestSettingsCard(),
          const SizedBox(height: 26),

          const _SectionTitle('내 포트폴리오'),
          const SizedBox(height: 6),
          if (app.positions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  '아직 종목이 없습니다.',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
            ),
          ...app.positions.map((p) => _StockCard(p, usd2, pct1)).toList(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: CupertinoColors.systemGrey,
      ),
    ),
  );
}


class _InvestSettingsCard extends StatefulWidget {
  const _InvestSettingsCard();

  @override
  State<_InvestSettingsCard> createState() => _InvestSettingsCardState();
}


class _InvestSettingsCardState extends State<_InvestSettingsCard> {
  late final TextEditingController _goalCtl;
  late final TextEditingController _monthlyCtl;

  bool _editGoal = false; // 목표 월배당 편집 여부
  bool _editMonthly = false; // 월 투자 금액 편집 여부

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _goalCtl = TextEditingController(
      text: app.targetPerMonth.toStringAsFixed(0),
    );
    _monthlyCtl = TextEditingController(
      text: app.monthlyContribution.toStringAsFixed(0),
    );
  }

  void _saveGoal() {
    context.read<AppState>().updateGoal(double.tryParse(_goalCtl.text) ?? 0);
    setState(() => _editGoal = false);
  }

  void _cancelGoal() {
    final app = context.read<AppState>();
    _goalCtl.text = app.targetPerMonth.toStringAsFixed(0);
    setState(() => _editGoal = false);
  }

  void _saveMonthly() {
    context.read<AppState>().updateMonthlyContribution(
      double.tryParse(_monthlyCtl.text) ?? 0,
    );
    setState(() => _editMonthly = false);
  }

  void _cancelMonthly() {
    final app = context.read<AppState>();
    _monthlyCtl.text = app.monthlyContribution.toStringAsFixed(0);
    setState(() => _editMonthly = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    const label = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
    const value = TextStyle(fontSize: 15);

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('목표 월배당금', style: label)),
              if (_editGoal) ...[
                SizedBox(
                  width: 100,
                  child: CupertinoTextField(
                    controller: _goalCtl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),

                const SizedBox(width: 10),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      minSize: 0,
                      padding: EdgeInsets.zero,
                      onPressed: _saveGoal,
                      child: const Icon(CupertinoIcons.check_mark_circled),
                    ),

                    const SizedBox(width: 10),

                    CupertinoButton(
                      minSize: 0,
                      padding: EdgeInsets.zero,
                      onPressed: _cancelGoal,
                      child: const Icon(
                        CupertinoIcons.xmark_circle,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(app.targetPerMonth.toStringAsFixed(0), style: value),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.pencil),
                  onPressed: () => setState(() => _editGoal = true),
                ),
              ],
            ],
          ),

          // ── 월 투자 금액 행 ──
          Row(
            children: [
              const Expanded(child: Text('월 투자 금액', style: label)),
              if (_editMonthly) ...[
                SizedBox(
                  width: 100,
                  child: CupertinoTextField(
                    controller: _monthlyCtl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),

                const SizedBox(width: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      minSize: 0,
                      padding: EdgeInsets.zero,
                      onPressed: _saveMonthly,
                      child: const Icon(CupertinoIcons.check_mark_circled),
                    ),
                    const SizedBox(width: 10), // 아이콘 간격 아주 좁게
                    CupertinoButton(
                      minSize: 0,
                      padding: EdgeInsets.zero,
                      onPressed: _cancelMonthly,
                      child: const Icon(
                        CupertinoIcons.xmark_circle,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(app.monthlyContribution.toStringAsFixed(0), style: value),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.pencil),
                  onPressed: () => setState(() => _editMonthly = true),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _goalCtl.dispose();
    _monthlyCtl.dispose();
    super.dispose();
  }
}


class _StockCard extends StatelessWidget {
  final StockPosition p;
  final NumberFormat usd;
  final NumberFormat pct;
  const _StockCard(this.p, this.usd, this.pct);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMenu(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  p.symbol,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  usd.format(p.evaluation),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chip('Qty', '${p.quantity}'),
                _chip('Avg', usd.format(p.avgCost)),
                _chip('Price', usd.format(p.currentPrice)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chip('Yield', pct.format(p.dividendYield)),
                _chip('Div Grow', pct.format(p.dividendGrowthRate)),
                _chip('Px Grow', pct.format(p.priceGrowthRate)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t, String v) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    decoration: BoxDecoration(
      color: CupertinoColors.systemGrey5,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Text(
          '$t: ',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(v, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );

  void _showMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                child: const Text('편집하기'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    InputFormScreen.route,
                    arguments: p,
                  );
                },
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                child: const Text('삭제하기'),
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('취소'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text('삭제하시겠습니까?'),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('삭제'),
                onPressed: () {
                  context.read<AppState>().removePosition(p);
                  Navigator.pop(context);
                },
              ),
              CupertinoDialogAction(
                child: const Text('취소'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}


class _CalcButton extends StatelessWidget {
  const _CalcButton();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom + 16,
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: BorderRadius.circular(12),
        child: const Text('계산', style: TextStyle(fontSize: 17)),
        onPressed: () {
          if (context.read<AppState>().positions.isEmpty) {
            showCupertinoDialog(
              context: context,
              builder:
                  (_) => const CupertinoAlertDialog(
                    title: Text('알림'),
                    content: Text('종목을 먼저 추가해 주세요.'),
                  ),
            );
            return;
          }
          Navigator.pushNamed(context, ResultScreen.route);
        },
      ),
    );
  }
}
