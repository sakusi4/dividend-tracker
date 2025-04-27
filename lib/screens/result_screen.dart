import 'dart:math' as math;

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

enum _Gran { month, quarter, year }

class _ResultScreenState extends State<ResultScreen> {
  static const Map<String, int> _segMap = {
    '3Y': 36,
    '5Y': 60,
    '10Y': 120,
    'Goal': -1, // 목표 달성 시점까지
  };

  _Gran _gran = _Gran.month;

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

  static const int _batch = 30;
  int _loaded = _batch;

  List<_Row> _filterRows(List<_Row> src) {
    switch (_gran) {
      case _Gran.month:
        return src; // 모두 보여줌
      case _Gran.quarter:
        return [
          for (int i = 0; i < src.length; i++)
            if ((i + 1) % 3 == 0) src[i], // 3,6,9,… 달만
        ];
      case _Gran.year:
        return [
          for (int i = 0; i < src.length; i++)
            if ((i + 1) % 12 == 0) src[i], // 12,24,36,… 달만
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final positions = app.positions;
    if (positions.isEmpty) {
      return const CupertinoPageScaffold(
        child: Center(child: Text('포트폴리오가 없습니다.')),
      );
    }

    // 30년 최대
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

    final rowsAll = f.rows.take(horizon).toList();
    final rowsView = _filterRows(rowsAll);

    // 로드 수 한계 보정
    _loaded = _loaded.clamp(0, rowsView.length);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('예측 결과')),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSegment()),
            SliverToBoxAdapter(
              child: _buildChartCard(chartData, app.targetPerMonth),
            ),
            SliverToBoxAdapter(child: _buildGranularitySegment()),

            // ── 무한 스크롤 SliverList ──
            SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                if (i == _loaded - 1 && _loaded < rowsView.length) {
                  Future.microtask(
                    () => setState(() {
                      _loaded = (_loaded + _batch).clamp(0, rowsView.length);
                    }),
                  );
                }
                return _buildDataCard(rowsView[i], app.targetPerMonth);
              }, childCount: _loaded),
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
  Widget _buildChartCard(List<_Point> quarterlyData, double target) {
    // 1) 연도 집계
    final data = toYearly(quarterlyData);

    // 2) 최대 Y 계산
    final maxY = data.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.1;

    // 3) UI
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
          title: const ChartTitle(
            text: '연도별 배당 추이', // ← 변경
            textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          plotAreaBorderWidth: 0,
          primaryXAxis: NumericAxis(
            interval: 1, // ← 1년 단위 눈금
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(color: CupertinoColors.systemGrey4),
            numberFormat: NumberFormat('0'), // 연도 표기에 소수점 제거
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
            // 목표선: 첫 해 ~ 마지막 해
            LineSeries<_Point, double>(
              dataSource: [
                _Point(data.first.x, target),
                _Point(data.last.x, target),
              ],
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
                    const SizedBox(width: 5),
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
                _infoChip('투입자본', _fmt0.format(r.cost)),
                _infoChip('손익', _fmt0.format(r.unrealized)),
                _infoChip('실현배당률', _pct.format(r.realizedYield)),
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

  Widget _buildGranularitySegment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CupertinoSlidingSegmentedControl<_Gran>(
        groupValue: _gran,
        children: const {
          _Gran.month: Text('월별'),
          _Gran.quarter: Text('분기별'),
          _Gran.year: Text('연도별'),
        },
        onValueChanged: (g) => setState(() => _gran = g ?? _gran),
      ),
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

    // ── 동적 상태 ──
    final shares = positions.map((p) => p.quantity).toList();
    final prices = positions.map((p) => p.currentPrice).toList();
    final yields = positions.map((p) => p.dividendYield).toList();

    // ── 월 성장 계수 (복리) ──
    final monthlyPriceFactor =
        positions
            .map<double>(
              (p) => math.pow(1 + p.priceGrowthRate, 1 / 12) as double,
            )
            .toList();
    final monthlyYieldFactor =
        positions
            .map<double>(
              (p) => math.pow(1 + p.dividendGrowthRate, 1 / 12) as double,
            )
            .toList();

    // ── 투자 원금(초기 매입가) ──
    double invested = positions.fold(0.0, (s, p) => s + p.quantity * p.avgCost);

    int? hit;
    final totalMonths = maxYears * 12;

    for (int m = 0; m < totalMonths; m++) {
      // ─────────────────────────────────────────────
      // 1) 월말 매수 (allocationRate 비율로 분배 매수)
      // ─────────────────────────────────────────────
      for (int i = 0; i < positions.length; i++) {
        final buyCash = monthlyContribution * positions[i].allocationRate;
        shares[i] += buyCash / prices[i];
      }
      invested += monthlyContribution; // 실제 사용한 자본 누적

      // ─────────────────────────────────────────────
      // 2) 가격·배당 월 성장 적용
      // ─────────────────────────────────────────────
      for (int i = 0; i < positions.length; i++) {
        prices[i] *= monthlyPriceFactor[i];
        yields[i] *= monthlyYieldFactor[i];
      }

      // ─────────────────────────────────────────────
      // 3) 평가금·배당 계산 (매수분 포함)
      // ─────────────────────────────────────────────
      double monthDivTotal = 0;
      double portfolioValue = 0;

      for (int i = 0; i < positions.length; i++) {
        final divPerShare = prices[i] * yields[i];
        monthDivTotal += shares[i] * divPerShare / 12;
        portfolioValue += shares[i] * prices[i];
      }

      // ── 포인트/행 저장 ──
      pts.add(_Point(m.toDouble(), monthDivTotal));

      final annualDiv = monthDivTotal * 12;
      final unrealized = portfolioValue - invested;
      final yieldOnCost = annualDiv / portfolioValue;

      rows.add(
        _Row(
          DateTime.now().add(Duration(days: 30 * (m + 1))),
          prices.first, // 시각화용 대표
          prices.first * yields.first,
          shares.reduce((a, b) => a + b), // 총 주식 수
          monthDivTotal,
          portfolioValue,
          invested,
          unrealized,
          yieldOnCost,
        ),
      );

      // 목표 달성 시점 기록
      if (hit == null && monthDivTotal >= target) hit = m + 1;
    }

    return _Forecast(points: pts, rows: rows, hitMonth: hit);
  }

  // 월별 데이터에서 연도별 스냅샷만 추출한다.
  // 매 12개월(0‑based index 11, 23, …) 시점의 값을 그대로 사용해
  List<_Point> toYearly(List<_Point> monthly) {
    final List<_Point> out = [];
    for (int i = 11; i < monthly.length; i += 12) {
      final yearIdx = (i ~/ 12) + 1;
      out.add(_Point(yearIdx.toDouble(), monthly[i].y));
    }
    return out;
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
  final double cost;
  final double unrealized;
  final double realizedYield;

  _Row(
    this.date,
    this.price,
    this.divPerShare,
    this.shares,
    this.monthDiv,
    this.value,
    this.cost,
    this.unrealized,
    this.realizedYield,
  );
}

class _Forecast {
  final List<_Point> points;
  final List<_Row> rows;
  final int? hitMonth;
  _Forecast({required this.points, required this.rows, this.hitMonth});
}
