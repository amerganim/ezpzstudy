import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Renders the actual graph/chart for a "describe the graph" writing question.
///
/// The question's data (e.g. "2019 – 70%, 2020 – 75%, …") already lives in the
/// prompt text, so [parseChartFromPrompt] extracts the label→value pairs and we
/// draw a real bar / line / pie chart (or a table) from them with a
/// CustomPainter — no image assets, fully offline. If the data can't be parsed
/// confidently, the caller simply shows the text as before.

enum ChartType { bar, line, pie, table }

class ChartPoint {
  final String label;
  final double value;
  const ChartPoint(this.label, this.value);
}

class ChartSpec {
  final ChartType type;
  final List<ChartPoint> points;
  final String unit; // '%', 'hours', '' …

  const ChartSpec(this.type, this.points, this.unit);
}

const _months = {
  'january', 'february', 'march', 'april', 'may', 'june', 'july', 'august',
  'september', 'october', 'november', 'december'
};

/// Distinct, print-friendly palette for bars / pie slices.
const _palette = <Color>[
  Color(0xFF2E7D6B), // teal (brand)
  Color(0xFF4C9AA6),
  Color(0xFFF9A825), // amber
  Color(0xFF5C7CFA), // blue
  Color(0xFF9C6ADE), // purple
  Color(0xFFEF6C00), // orange
  Color(0xFF43A047), // green
  Color(0xFFE05252), // red
];

ChartSpec? parseChartFromPrompt(String prompt) {
  final lower = prompt.toLowerCase();

  ChartType type;
  if (lower.contains('pie chart')) {
    type = ChartType.pie;
  } else if (lower.contains('table')) {
    type = ChartType.table;
  } else {
    type = ChartType.bar; // maybe refined to line below
  }

  final chunks = prompt.replaceAll(' and ', ', ').split(',');
  final numRe = RegExp(r'(\d+(?:\.\d+)?)');
  final points = <ChartPoint>[];
  var unit = '';

  for (var chunk in chunks) {
    // Drop intro text before a colon ("… over five years: 2019 – 70%").
    if (chunk.contains(':')) chunk = chunk.substring(chunk.lastIndexOf(':') + 1);
    chunk = chunk.trim();
    if (chunk.isEmpty) continue;

    final matches = numRe.allMatches(chunk).toList();
    if (matches.isEmpty) continue;
    final last = matches.last;
    final value = double.tryParse(last.group(1)!);
    if (value == null) continue;

    final after = chunk.substring(last.end).trimLeft().toLowerCase();
    if (after.startsWith('%')) {
      unit = '%';
    } else if (after.startsWith('hour')) {
      unit = 'hours';
    }

    var label = chunk.substring(0, last.start).trim();
    label = label.replaceAll(RegExp(r'[–\-:]+$'), '').trim();
    if (label.isEmpty || label.length > 28) continue;
    if (label.split(RegExp(r'\s+')).length > 4) continue; // avoid sentence bits

    points.add(ChartPoint(label, value));
  }

  if (points.length < 2 || points.length > 12) return null;

  // A "graph" of a time series reads better as a line.
  if (type == ChartType.bar && !lower.contains('bar')) {
    final timeSeries = points.every((p) {
      final l = p.label.toLowerCase();
      return RegExp(r'^(19|20)\d{2}$').hasMatch(p.label) ||
          RegExp(r'^day\s*\d+$').hasMatch(l) ||
          _months.contains(l);
    });
    if (timeSeries && lower.contains('graph')) type = ChartType.line;
  }

  return ChartSpec(type, points, unit);
}

/// A framed chart shown above a graph-description prompt.
class ChartCard extends StatelessWidget {
  final ChartSpec spec;
  const ChartCard({super.key, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: spec.type == ChartType.table
          ? _TableView(spec: spec)
          : (spec.type == ChartType.pie
              ? _PieView(spec: spec)
              : SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: _AxisChartPainter(spec),
                    size: Size.infinite,
                  ),
                )),
    );
  }
}

String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';

// ── Bar & line ────────────────────────────────────────────────────────────────

class _AxisChartPainter extends CustomPainter {
  final ChartSpec spec;
  _AxisChartPainter(this.spec);

  @override
  void paint(Canvas canvas, Size size) {
    final pts = spec.points;
    final maxV = pts.map((p) => p.value).reduce(math.max);
    if (maxV <= 0) return;

    const topPad = 20.0; // room for value labels
    const bottomPad = 34.0; // room for x labels
    const leftPad = 4.0;
    final plotH = size.height - topPad - bottomPad;
    final plotW = size.width - leftPad * 2;
    final baseY = topPad + plotH;

    final axis = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    canvas.drawLine(Offset(leftPad, baseY), Offset(leftPad + plotW, baseY), axis);

    final n = pts.length;
    double xFor(int i) =>
        leftPad + plotW * (n == 1 ? 0.5 : (i + 0.5) / n);

    if (spec.type == ChartType.line) {
      final linePaint = Paint()
        ..color = AppTheme.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final dot = Paint()..color = AppTheme.accentDark;
      Offset? prev;
      for (var i = 0; i < n; i++) {
        final x = xFor(i);
        final y = baseY - plotH * (pts[i].value / maxV);
        final p = Offset(x, y);
        if (prev != null) canvas.drawLine(prev, p, linePaint);
        prev = p;
      }
      for (var i = 0; i < n; i++) {
        final x = xFor(i);
        final y = baseY - plotH * (pts[i].value / maxV);
        canvas.drawCircle(Offset(x, y), 3.5, dot);
        _text(canvas, _fmt(pts[i].value) + spec.unit.replaceAll('hours', ''),
            Offset(x, y - 15), 11, AppTheme.accentDark, center: true, bold: true);
        _xLabel(canvas, pts[i].label, x, baseY + 5, plotW / n);
      }
    } else {
      // bar
      final slot = plotW / n;
      final barW = math.min(slot * 0.62, 42.0);
      for (var i = 0; i < n; i++) {
        final cx = xFor(i);
        final h = plotH * (pts[i].value / maxV);
        final rect = Rect.fromLTWH(cx - barW / 2, baseY - h, barW, h);
        final paint = Paint()..color = _palette[i % _palette.length];
        canvas.drawRRect(
            RRect.fromRectAndCorners(rect,
                topLeft: const Radius.circular(4),
                topRight: const Radius.circular(4)),
            paint);
        _text(canvas, _fmt(pts[i].value) + spec.unit.replaceAll('hours', ''),
            Offset(cx, baseY - h - 15), 11, Colors.black87, center: true, bold: true);
        _xLabel(canvas, pts[i].label, cx, baseY + 5, slot);
      }
    }
  }

  void _xLabel(Canvas canvas, String label, double cx, double top, double maxW) {
    _text(canvas, label, Offset(cx, top), 10.5, Colors.black54,
        center: true, maxWidth: maxW - 2);
  }

  void _text(Canvas canvas, String s, Offset at, double size, Color color,
      {bool center = false, bool bold = false, double? maxWidth}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final dx = center ? at.dx - tp.width / 2 : at.dx;
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  bool shouldRepaint(covariant _AxisChartPainter old) => old.spec != spec;
}

// ── Pie ───────────────────────────────────────────────────────────────────────

class _PieView extends StatelessWidget {
  final ChartSpec spec;
  const _PieView({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: CustomPaint(
            painter: _PiePainter(spec),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < spec.points.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text(
                    '${spec.points[i].label} '
                    '(${_fmt(spec.points[i].value)}${spec.unit})',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final ChartSpec spec;
  _PiePainter(this.spec);

  @override
  void paint(Canvas canvas, Size size) {
    final total = spec.points.fold<double>(0, (s, p) => s + p.value);
    if (total <= 0) return;
    final r = math.min(size.width, size.height) / 2 - 6;
    final center = Offset(size.width / 2, size.height / 2);
    var start = -math.pi / 2;
    for (var i = 0; i < spec.points.length; i++) {
      final sweep = spec.points[i].value / total * 2 * math.pi;
      final paint = Paint()..color = _palette[i % _palette.length];
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: r), start, sweep, true, paint);
      // percentage label at the slice mid-angle
      final mid = start + sweep / 2;
      final lx = center.dx + math.cos(mid) * r * 0.6;
      final ly = center.dy + math.sin(mid) * r * 0.6;
      final pct = (spec.points[i].value / total * 100).round();
      if (pct >= 6) {
        final tp = TextPainter(
          text: TextSpan(
              text: '$pct%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => old.spec != spec;
}

// ── Table ─────────────────────────────────────────────────────────────────────

class _TableView extends StatelessWidget {
  final ChartSpec spec;
  const _TableView({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: AppTheme.hairline),
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
      children: [
        for (var i = 0; i < spec.points.length; i++)
          TableRow(
            decoration: BoxDecoration(
                color: i.isEven ? AppTheme.surfaceTint : Colors.white),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Text(spec.points[i].label,
                    style: const TextStyle(fontSize: 14)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Text('${_fmt(spec.points[i].value)}${spec.unit}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
      ],
    );
  }
}
