import 'package:flutter/material.dart';

import '../reading/domain/grass_github_palette.dart';
import '../reading/domain/grass_intensity.dart';

const _monthAbbr = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// Month label for the week column that contains the **1st** of a month in
/// `[windowStart, windowEnd]`, else empty (GitHub-style strip).
String monthAbbrevForGrassWeek(
  List<DateTime> week,
  DateTime windowStart,
  DateTime windowEnd,
) {
  final ws = DateTime(windowStart.year, windowStart.month, windowStart.day);
  final we = DateTime(windowEnd.year, windowEnd.month, windowEnd.day);
  for (final day in week) {
    final d = DateTime(day.year, day.month, day.day);
    if (d.day == 1 && !d.isBefore(ws) && !d.isAfter(we)) {
      return _monthAbbr[d.month - 1];
    }
  }
  return '';
}

/// Sunday-first padded day list for the month (full weeks only).
List<DateTime> flatMonthCellsSundayFirst(DateTime month) {
  final y = month.year;
  final m = month.month;
  final start = DateTime(y, m, 1);
  final end = DateTime(y, m + 1, 0);
  return flatDateRangeCellsSundayFirst(start, end);
}

/// Padded Sundays-through-Saturdays grid covering **[inclusiveStart, inclusiveEnd]**.
List<DateTime> flatDateRangeCellsSundayFirst(
  DateTime inclusiveStart,
  DateTime inclusiveEnd,
) {
  final s = DateTime(
    inclusiveStart.year,
    inclusiveStart.month,
    inclusiveStart.day,
  );
  final e = DateTime(inclusiveEnd.year, inclusiveEnd.month, inclusiveEnd.day);
  final lead = s.weekday % 7;
  final gridStart = s.subtract(Duration(days: lead));
  final spanDays = e.difference(gridStart).inDays + 1;
  final trail = (7 - spanDays % 7) % 7;
  final n = spanDays + trail;
  return List.generate(n, (i) {
    final x = gridStart.add(Duration(days: i));
    return DateTime(x.year, x.month, x.day);
  });
}

List<List<DateTime>> chunkWeeks(List<DateTime> flat) {
  assert(flat.length % 7 == 0);
  return [for (var i = 0; i < flat.length; i += 7) flat.sublist(i, i + 7)];
}

bool _inDateWindow(DateTime day, DateTime windowStart, DateTime windowEnd) {
  final d = DateTime(day.year, day.month, day.day);
  final a = DateTime(windowStart.year, windowStart.month, windowStart.day);
  final b = DateTime(windowEnd.year, windowEnd.month, windowEnd.day);
  return !d.isBefore(a) && !d.isAfter(b);
}

/// GitHub profile–style strip: **columns = weeks** (old → new, newest on the
/// right), **rows = Sun–Sat**, horizontal scroll; initial position at the right.
class GithubContributionStrip extends StatefulWidget {
  const GithubContributionStrip({
    super.key,
    required this.windowStart,
    required this.windowEnd,
    required this.dayTotals,
    required this.windowMaxPages,
    required this.onDayTap,
  });

  /// Inclusive date-only start of the “active” window (colored intensity).
  final DateTime windowStart;

  /// Inclusive date-only end of the active window.
  final DateTime windowEnd;

  final Map<DateTime, int> dayTotals;
  final int windowMaxPages;
  final void Function(DateTime day) onDayTap;

  /// Square day cell (logical px); larger = easier tap + read at a glance.
  static const double _cell = 22;
  static const double _gap = 3;
  static const double _labelRowH = 16;

  @override
  State<GithubContributionStrip> createState() =>
      _GithubContributionStripState();
}

class _GithubContributionStripState extends State<GithubContributionStrip> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
  }

  @override
  void didUpdateWidget(GithubContributionStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final a = oldWidget.windowStart;
    final b = widget.windowStart;
    final c = oldWidget.windowEnd;
    final d = widget.windowEnd;
    if (a.year != b.year ||
        a.month != b.month ||
        a.day != b.day ||
        c.year != d.year ||
        c.month != d.month ||
        c.day != d.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
    }
  }

  @override
  Widget build(BuildContext context) {
    final flat = flatDateRangeCellsSundayFirst(
      widget.windowStart,
      widget.windowEnd,
    );
    final weeks = chunkWeeks(flat);
    const rowLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final colW = GithubContributionStrip._cell + GithubContributionStrip._gap;
    final gridH =
        7 * GithubContributionStrip._cell + 6 * GithubContributionStrip._gap;
    final labelH = GithubContributionStrip._labelRowH;
    final stripH = labelH + gridH;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            height: stripH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: labelH),
                SizedBox(
                  height: gridH,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var r = 0; r < 7; r++)
                        SizedBox(
                          height: GithubContributionStrip._cell,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              rowLabels[r],
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SizedBox(
              height: stripH,
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: labelH,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final week in weeks)
                            SizedBox(
                              width: colW,
                              height: labelH,
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  monthAbbrevForGrassWeek(
                                    week,
                                    widget.windowStart,
                                    widget.windowEnd,
                                  ),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final week in weeks)
                          SizedBox(
                            width: colW,
                            height: gridH,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final day in week)
                                  _GithubGrassCell(
                                    size: GithubContributionStrip._cell,
                                    day: day,
                                    windowStart: widget.windowStart,
                                    windowEnd: widget.windowEnd,
                                    dayTotals: widget.dayTotals,
                                    windowMaxPages: widget.windowMaxPages,
                                    onTap: () => widget.onDayTap(day),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One calendar month inside the sheet (same strip, month-bounded window).
class MonthGithubContributionStrip extends StatelessWidget {
  const MonthGithubContributionStrip({
    super.key,
    required this.month,
    required this.dayTotals,
    required this.monthMaxPages,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<DateTime, int> dayTotals;
  final int monthMaxPages;
  final void Function(DateTime day) onDayTap;

  @override
  Widget build(BuildContext context) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return GithubContributionStrip(
      key: ValueKey(month),
      windowStart: start,
      windowEnd: end,
      dayTotals: dayTotals,
      windowMaxPages: monthMaxPages,
      onDayTap: onDayTap,
    );
  }
}

class _GithubGrassCell extends StatelessWidget {
  const _GithubGrassCell({
    required this.size,
    required this.day,
    required this.windowStart,
    required this.windowEnd,
    required this.dayTotals,
    required this.windowMaxPages,
    required this.onTap,
  });

  final double size;
  final DateTime day;
  final DateTime windowStart;
  final DateTime windowEnd;
  final Map<DateTime, int> dayTotals;
  final int windowMaxPages;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inWindow = _inDateWindow(day, windowStart, windowEnd);
    final key = DateTime(day.year, day.month, day.day);
    final pages = dayTotals[key] ?? 0;
    final maxP = windowMaxPages;
    final level = inWindow ? grassIntensityLevel(pages, maxP) : 0;
    final today = DateUtils.isSameDay(day, DateTime.now());

    if (!inWindow) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: githubGrassCellBorder, width: 0.5),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: githubGrassCellFill(level),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: today ? githubGrassTodayBorder : githubGrassCellBorder,
              width: today ? 2 : 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
