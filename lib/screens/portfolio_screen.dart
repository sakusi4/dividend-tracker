import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('목표 설정'),
                  const _InvestSettingsCard(),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('요약'),
                  const _InvestSummaryCard(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          const _SectionTitle('내 자산 비율'),
          if (app.positions.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  '아직 종목이 없습니다.',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
            ),
          ] else ...[
            SizedBox(height: 250, child: _AllocationPieChart()),
            const SizedBox(height: 16),
          ],

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

class _InvestSummaryCard extends StatelessWidget {
  const _InvestSummaryCard();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    const label = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
    const value = TextStyle(fontSize: 15);

    final totalValue = app.positions.fold<double>(
      0.0,
      (sum, p) => sum + p.evaluation,
    );

    return Container(
      constraints: const BoxConstraints(
        minWidth: 150, // ← 원하는 최소 폭
        // maxWidth: double.infinity  // 최대는 제한 없음(기본값)
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('총 평가금', style: label),
          const SizedBox(height: 5),
          Text('\$${totalValue.toStringAsFixed(2)}', style: value),
        ],
      ),
    );
  }
}

class _InvestSettingsCard extends StatefulWidget {
  const _InvestSettingsCard({super.key});
  @override
  State<_InvestSettingsCard> createState() => _InvestSettingsCardState();
}

class _InvestSettingsCardState extends State<_InvestSettingsCard> {
  Future<void> _showEditPopup() async {
    final app = context.read<AppState>();
    final goalCtl = TextEditingController(
      text:
          app.targetPerMonth == 0 ? '' : app.targetPerMonth.toStringAsFixed(0),
    );
    final monthlyCtl = TextEditingController(
      text:
          app.monthlyContribution == 0
              ? ''
              : app.monthlyContribution.toStringAsFixed(0),
    );

    await showCupertinoDialog<void>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('목표 설정'),
            content: Column(
              children: [
                const SizedBox(height: 8),
                _CupertinoField(
                  label: '목표 월 배당금',
                  controller: goalCtl,
                  placeholder: 'USD',
                ),
                const SizedBox(height: 12),
                _CupertinoField(
                  label: '월 투자 금액',
                  controller: monthlyCtl,
                  placeholder: 'USD',
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('저장'),
                onPressed: () {
                  context.read<AppState>()
                    ..updateGoal(double.tryParse(goalCtl.text) ?? 0)
                    ..updateMonthlyContribution(
                      double.tryParse(monthlyCtl.text) ?? 0,
                    );
                  Navigator.pop(ctx);
                },
              ),
              CupertinoDialogAction(
                child: const Text('취소'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    const label = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
    const value = TextStyle(fontSize: 15);

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('목표 월 배당금', style: label),
              const SizedBox(width: 10),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 12,
                onPressed: _showEditPopup,
                child: const Icon(CupertinoIcons.pencil),
              ),
            ],
          ),
          // 표시용 값들
          Text(
            app.targetPerMonth == 0
                ? '설정해 주세요!'
                : '\$${app.targetPerMonth.toStringAsFixed(0)}',
            style: value,
          ),
          const SizedBox(height: 8),
          Text('월 투자 금액', style: label),
          Text(
            app.monthlyContribution == 0
                ? '설정해 주세요!'
                : '\$${app.monthlyContribution.toStringAsFixed(0)}',
            style: value,
          ),
        ],
      ),
    );
  }
}

class _CupertinoField extends StatelessWidget {
  const _CupertinoField({
    required this.label,
    required this.controller,
    this.placeholder = '',
  });
  final String label;
  final String placeholder;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          label,
          style: const TextStyle(color: CupertinoColors.systemGrey),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      textAlign: TextAlign.end,
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

class _StockCard extends StatefulWidget {
  final StockPosition p;
  final NumberFormat usd;
  final NumberFormat pct;
  const _StockCard(this.p, this.usd, this.pct);

  @override
  State<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<_StockCard> {
  late final TextEditingController _allocCtl;

  @override
  void initState() {
    super.initState();
    _allocCtl = TextEditingController(
      text: (widget.p.allocationRate * 100).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _allocCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;

    return GestureDetector(
      behavior: HitTestBehavior.translucent, // 빈 공간 터치 감지
      onTap: () {
        FocusScope.of(context).unfocus(); // 키보드 내려감
      },
      onLongPress: () => _showMenu(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 심볼과 평가금
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
                Row(
                  children: [
                    const Text(
                      '평가금',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.usd.format(p.evaluation),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 칩 그룹 1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chip('보유주', '${p.quantity}'),
                _chip('평단가', widget.usd.format(p.avgCost)),
                _chip('주가', widget.usd.format(p.currentPrice)),
              ],
            ),
            const SizedBox(height: 8),
            // 칩 그룹 2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chip('배당률', widget.pct.format(p.dividendYield)),
                _chip('배당성장률', widget.pct.format(p.dividendGrowthRate)),
                _chip('주가성장률', widget.pct.format(p.priceGrowthRate)),
              ],
            ),
            const SizedBox(height: 8),
            // 배분 비율 입력
            Row(
              children: [
                const Spacer(),
                const Text(
                  '배분 비율',
                  style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.systemGrey,
                      ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  child: Row(
                    children: [
                      Text(
                        '${(widget.p.allocationRate * 100).toStringAsFixed(0)} %',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 1),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 12,
                        onPressed: () => _showAllocationPopup(context),
                        child: const Icon(CupertinoIcons.pencil),
                      ),
                    ],
                  ),
                ),
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
                    arguments: widget.p,
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
                  context.read<AppState>().removePosition(widget.p);
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

  void _showAllocationPopup(BuildContext context) async {
    final allocCtl = TextEditingController(
      text: (widget.p.allocationRate * 100).toStringAsFixed(0),
    );

    await showCupertinoDialog<void>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('배분 비율 (%)'),
            content: Column(
              children: [
                const SizedBox(height: 8),
                _CupertinoField(label: '배분비율', controller: allocCtl),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('저장'),
                onPressed: () {
                  final val = int.tryParse(allocCtl.text);
                  final isValid = val != null && val > 0 && val <= 100;

                  if (!isValid) {
                    showCupertinoDialog(
                      context: context,
                      builder:
                          (_) => CupertinoAlertDialog(
                            title: const Text('입력 오류'),
                            content: const Text('0부터 100까지의 정수를 입력하세요.'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('확인'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                    );
                    return; // 저장 중단
                  }

                  context.read<AppState>().updateAllocation(
                    widget.p,
                    val! / 100,
                  ); // 안전하게 val 사용
                  Navigator.pop(ctx); // 편집 팝업 닫기
                },
              ),
              CupertinoDialogAction(
                child: const Text('취소'),
                onPressed: () => Navigator.pop(ctx),
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
                  (_) => CupertinoAlertDialog(
                    title: const Text('알림'),
                    content: const Text('종목을 먼저 추가해 주세요.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('확인'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
            );
            return;
          } else if (context.read<AppState>().targetPerMonth == 0) {
            showCupertinoDialog(
              context: context,
              builder:
                  (_) => CupertinoAlertDialog(
                    title: const Text('알림'),
                    content: const Text('목표 월 배당금을 설정해 주세요.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('확인'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
            );
            return;
          } else if (context.read<AppState>().monthlyContribution == 0) {
            showCupertinoDialog(
              context: context,
              builder:
                  (_) => CupertinoAlertDialog(
                    title: const Text('알림'),
                    content: const Text('월 투자 금액을 설정해 주세요.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('확인'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
            );
            return;
          }

          final app = context.read<AppState>();
          final allocSum = app.positions.fold<double>(
            0.0,
            (s, p) => s + p.allocationRate,
          );
          if (app.positions.isNotEmpty && (allocSum - 1).abs() > 0.001) {
            showCupertinoDialog(
              context: context,
              builder:
                  (_) => CupertinoAlertDialog(
                    title: const Text('알림'),
                    content: const Text('배분 비율의 합이 100%가 되도록 설정해 주세요.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('확인'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
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

class _AllocationPieChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final positions = context.watch<AppState>().positions;
    final total = positions.fold<double>(0, (sum, p) => sum + p.evaluation);
    final data =
        total > 0
            ? positions
                .map((p) => _PieData(p.symbol, p.evaluation / total * 100))
                .toList()
            : <_PieData>[];

    return SfCircularChart(
      title: ChartTitle(
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
      ),

      palette: const <Color>[
        Color(0xFF81C784), // 연녹색
        Color(0xFF4FC3F7), // 연파랑
        Color(0xFFFFF176), // 연노랑
        Color(0xFFBA68C8), // 연보라
        Color(0xFFFF8A65), // 연코랄
        Color(0xFF90A4AE), // 연회색
      ],
      series: <DoughnutSeries<_PieData, String>>[
        DoughnutSeries<_PieData, String>(
          dataSource: data,
          xValueMapper: (d, _) => d.symbol,
          yValueMapper: (d, _) => d.percent,
          dataLabelMapper: (d, _) => '${d.percent.toStringAsFixed(0)}%',
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.inside,
            textStyle: TextStyle(fontSize: 12, color: Colors.white),
          ),
          // 도넛 스타일
          radius: '100%',
          innerRadius: '70%',
          explode: false,
          // 세그먼트 간 경계
          strokeColor: Colors.white,
          strokeWidth: 1,
        ),
      ],
    );
  }
}

class _PieData {
  final String symbol;
  final double percent;
  _PieData(this.symbol, this.percent);
}
