import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../models/position.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});
  static const route = '/result';

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const Map<String, int> _segMap = {
    '3Y': 36,
    '5Y': 60,
    '10Y': 120,
    'Goal': -1, // 목표 달성 시점까지
  };
  late int _horizon = _segMap.values.first;


  final NumberFormat _fmt0 = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );
  final NumberFormat _fmt2 = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  final NumberFormat _pct = NumberFormat.decimalPercentPattern(
    decimalDigits: 1,
  );
  final NumberFormat _axisFmt = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );


  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final positions = app.positions;
    if (positions.isEmpty) {
      return const CupertinoPageScaffold(
        child: Center(child: Text('포트폴리오가 없습니다.')),
      );
    }

    // 계산 – 화면 내에서 즉석 처리 (30 년 한도)
    final _Forecast f = _runForecast(
      positions: positions,
      monthlyContribution: app.monthlyContribution,
      target: app.targetPerMonth,
      maxYears: 30,
    );

    // 기간 결정 – Goal 은 hitMonth까지, 없으면 전체
    final int horizon =
        (_horizon == -1) ? (f.hitMonth ?? f.points.length) : _horizon;

    final chartData = f.points.take(horizon).toList();
    final rows = f.rows.take(horizon).toList();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('예측 결과')),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSegment()),
            SliverToBoxAdapter(
              child: _buildChartCard(chartData, app.targetPerMonth),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildDataCard(rows[i], app.targetPerMonth),
                childCount: rows.length,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 상단 기간 세그먼트 ──
  Widget _buildSegment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: _horizon,
        children: {for (var e in _segMap.entries) e.value: Text(e.key)},
        onValueChanged: (v) => setState(() => _horizon = v ?? _horizon),
      ),
    );
  }

  // ── 메인 차트 카드 ──
  Widget _buildChartCard(List<_Point> data, double target) {
    final double maxY =
        data.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: SfCartesianChart(
          title: ChartTitle(
            text: '분기별 배당 추이',
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          plotAreaBorderWidth: 0,
          primaryXAxis: NumericAxis(
            interval: 3,
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(color: CupertinoColors.systemGrey4),
          ),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: maxY,
            interval: maxY / 4,
            majorGridLines: const MajorGridLines(
              color: CupertinoColors.systemGrey4,
              width: 0.5,
            ),
            labelFormat: '{value}',
            numberFormat: _axisFmt,
            axisLine: const AxisLine(color: CupertinoColors.systemGrey4),
          ),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <LineSeries<_Point, double>>[
            LineSeries<_Point, double>(
              dataSource: data,
              xValueMapper: (d, _) => d.x,
              yValueMapper: (d, _) => d.y,
              width: 2,
              color: CupertinoColors.activeBlue,
              markerSettings: const MarkerSettings(
                isVisible: true,
                shape: DataMarkerType.circle,
              ),
            ),
            LineSeries<_Point, double>(
              dataSource: [_Point(0, target), _Point(data.last.x, target)],
              xValueMapper: (d, _) => d.x,
              yValueMapper: (d, _) => d.y,
              width: 2,
              color: CupertinoColors.systemRed,
              dashArray: const <double>[4, 4],
            ),
          ],
        ),
      ),
    );
  }

  // ── 월별 카드 ──
  Widget _buildDataCard(_Row r, double target) {
    final double ratio = (r.monthDiv / target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 & 월배당
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('yy/MM').format(r.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '월배당',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(width: 5,),
                    Text(
                      _fmt2.format(r.monthDiv),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 진행 바
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              ratio >= 1
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.activeBlue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _pct.format(ratio),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        ratio >= 1
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _infoChip('평가금', _fmt0.format(r.value)),
                _infoChip('보유주', r.shares.toStringAsFixed(1)),
                _infoChip('주가', _fmt2.format(r.price)),
                _infoChip('배당/주', _fmt2.format(r.divPerShare)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $val', style: const TextStyle(fontSize: 11)),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  계산 엔진 (포트폴리오 전체)
  // ──────────────────────────────────────────────────────────────────────────
  _Forecast _runForecast({
    required List<StockPosition> positions,
    required double monthlyContribution,
    required double target,
    int maxYears = 30,
  }) {
    final List<_Point> pts = [];
    final List<_Row> rows = [];

    // 각 종목별 동적 상태를 배열로 유지
    final List<double> shares = positions.map((p) => p.quantity).toList();
    final List<double> prices = positions.map((p) => p.currentPrice).toList();
    final List<double> yields = positions.map((p) => p.dividendYield).toList();

    int? hit;
    final totalMonths = maxYears * 12;

    for (int m = 0; m < totalMonths; m++) {
      double monthDivTotal = 0;
      double portfolioValue = 0;

      for (int i = 0; i < positions.length; i++) {
        final divPerShare = prices[i] * yields[i];
        final monthDiv = shares[i] * divPerShare / 12;
        monthDivTotal += monthDiv;
        portfolioValue += shares[i] * prices[i];
      }

      pts.add(_Point(m.toDouble(), monthDivTotal));
      rows.add(
        _Row(
          DateTime.now().add(Duration(days: 30 * (m + 1))),
          // 평균 주가 & 배당 계산용, 첫 종목 기준. 필요에 따라 개선 가능
          prices.first,
          prices.first * yields.first,
          shares.reduce((a, b) => a + b),
          monthDivTotal,
          portfolioValue,
        ),
      );

      if (hit == null && monthDivTotal >= target) hit = m + 1;

      // 월말 매수 – 현재는 포트폴리오 첫 종목에 전액 투입 (단순화)
      if (monthlyContribution > 0 && positions.isNotEmpty) {
        shares[0] += monthlyContribution / prices[0];
      }

      // 연간 성장률 적용
      if ((m + 1) % 12 == 0) {
        for (int i = 0; i < positions.length; i++) {
          prices[i] *= (1 + positions[i].priceGrowthRate);
          yields[i] *= (1 + positions[i].dividendGrowthRate);
        }
      }
    }
    return _Forecast(points: pts, rows: rows, hitMonth: hit);
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  내부 자료구조
// ──────────────────────────────────────────────────────────────────────────
class _Point {
  final double x; // month index
  final double y; // monthly dividend
  _Point(this.x, this.y);
}

class _Row {
  final DateTime date;
  final double price;
  final double divPerShare;
  final double shares;
  final double monthDiv;
  final double value;
  _Row(
    this.date,
    this.price,
    this.divPerShare,
    this.shares,
    this.monthDiv,
    this.value,
  );
}

class _Forecast {
  final List<_Point> points;
  final List<_Row> rows;
  final int? hitMonth;
  _Forecast({required this.points, required this.rows, this.hitMonth});
}
