import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezpzstudy/ui/session/renderers/chart_view.dart';

void main() {
  // Real prompts from content/authoring/p1_graph_chart*.json.
  const prompts = <String>[
    'The graph shows the pass rate of a college in the HSC exam over five years: 2019 – 70%, 2020 – 75%, 2021 – 80%, 2022 – 78%, 2023 – 90%. Describe the graph in a paragraph.',
    'The pie chart shows how a student spends his 24 hours a day: Sleep – 8 hours, Study – 6 hours, School – 5 hours, Play – 2 hours, Others – 3 hours. Describe the chart.',
    'The bar graph shows the pass rate (%) of a school in the HSC exam over five years: 2020 – 70%, 2021 – 75%, 2022 – 68%, 2023 – 82%, 2024 – 90%. Describe the graph.',
    'The table shows the number of students in a college in four groups: Science 300, Business Studies 250, Humanities 200, and total girls 350. Describe the table in a paragraph.',
    'The graph shows the literacy rate of Bangladesh over five years: 2019 - 62%, 2020 - 65%, 2021 - 68%, 2022 - 72%, 2023 - 75%. Describe the graph in a paragraph.',
    'The graph shows the number of mobile phone users (in millions) in a country: 2018 - 90, 2019 - 110, 2020 - 130, 2021 - 150, 2022 - 170. Describe the graph.',
    'The pie chart shows how a family spends its monthly income: Food 40%, House rent 25%, Education 15%, Medical 10%, Savings 10%. Describe the chart.',
    'The table shows the favourite games of the students of a class: Football 20, Cricket 15, Badminton 8, Swimming 5, Others 2. Describe the table.',
    'The graph shows the number of trees planted in a school over five years: 2019 - 100, 2020 - 150, 2021 - 120, 2022 - 200, 2023 - 250. Describe the graph.',
    'The graph shows the yearly rainfall (in cm) of a district: January 5, April 20, July 55, October 30, December 8. Describe the graph.',
    'The pie chart shows the sources of energy used in a country: Gas 45%, Coal 20%, Oil 15%, Solar 12%, Others 8%. Describe the chart.',
    'The graph shows the population growth of a town (in thousands): 1990 - 20, 2000 - 35, 2010 - 55, 2020 - 80. Describe the graph.',
    'The graph shows the number of visitors to a book fair (in thousands) over a week: Day 1 - 10, Day 3 - 25, Day 5 - 40, Day 7 - 60. Describe the graph.',
    'The graph shows the export earnings of a country (in billion dollars): 2018 - 30, 2019 - 34, 2020 - 33, 2021 - 40, 2022 - 45. Describe the graph.',
    'The table shows the daily routine of a student (hours per day): Study 7, Sleep 8, School 5, Meals 2, Games 2. Describe the table.',
  ];

  test('every graph prompt parses into a chart with ≥2 sane points', () {
    for (final p in prompts) {
      final spec = parseChartFromPrompt(p);
      expect(spec, isNotNull, reason: 'failed to parse: $p');
      expect(spec!.points.length, greaterThanOrEqualTo(2), reason: p);
      expect(spec.points.length, lessThanOrEqualTo(8), reason: p);
      for (final pt in spec.points) {
        expect(pt.value, greaterThan(0), reason: '${pt.label} in: $p');
        expect(pt.label.isNotEmpty, isTrue, reason: p);
      }
    }
  });

  test('chart types are inferred correctly', () {
    ChartType t(String p) => parseChartFromPrompt(p)!.type;
    expect(t(prompts[1]), ChartType.pie); // "pie chart"
    expect(t(prompts[6]), ChartType.pie);
    expect(t(prompts[3]), ChartType.table); // "table"
    expect(t(prompts[7]), ChartType.table);
    expect(t(prompts[2]), ChartType.bar); // "bar graph"
    expect(t(prompts[0]), ChartType.line); // year-series "graph"
    expect(t(prompts[9]), ChartType.line); // months
    expect(t(prompts[12]), ChartType.line); // Day N
  });

  test('spot-check parsed values', () {
    final s = parseChartFromPrompt(prompts[0])!;
    expect(s.points.map((p) => p.label).toList(),
        ['2019', '2020', '2021', '2022', '2023']);
    expect(s.points.map((p) => p.value).toList(), [70, 75, 80, 78, 90]);
    expect(s.unit, '%');

    final games = parseChartFromPrompt(prompts[7])!;
    expect(games.points.first.label, 'Football');
    expect(games.points.first.value, 20);

    final visitors = parseChartFromPrompt(prompts[12])!;
    expect(visitors.points.map((p) => p.label).toList(),
        ['Day 1', 'Day 3', 'Day 5', 'Day 7']);
  });

  testWidgets('every prompt renders as a ChartCard without exceptions',
      (tester) async {
    for (final p in prompts) {
      final spec = parseChartFromPrompt(p)!;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 360, child: ChartCard(spec: spec)),
        ),
      ));
      expect(tester.takeException(), isNull, reason: p);
    }
  });
}
