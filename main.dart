// 好题精练 - 原生渲染 UI
// 一题一屏（PageView）/ 选项仅 ABCD / 网络请求不锁屏 / MD3 不规则图形加载动画
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'api.dart';
import 'models.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '好题精练',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B)),
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<GradeGroup> grades = [];
  List<Subject> subjects = [];
  List<Chapter> chapters = [];
  Grade? selGrade;
  Subject? selSubject;
  Publish? selPublish;
  Term? selTerm;
  Chapter? selChapter;
  bool loading = false;
  String log = '选择年级 / 科目 / 出版社 / 学期 / 章节，然后开始刷题';

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  // 统一的非阻塞加载包装：加载期间只显示角标，不锁屏
  Future<void> _guard(Future<void> Function() task) async {
    setState(() => loading = true);
    try {
      await task();
    } catch (e) {
      if (mounted) setState(() => log = '出错: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadGrades() => _guard(() async {
        grades = await EebbkApi.getGrades();
        log = '已加载 ${grades.expand((g) => g.grades).length} 个年级';
      });

  Future<void> _loadBooks() async {
    if (selGrade == null) return;
    await _guard(() async {
      subjects = await EebbkApi.getBooks(selGrade!.id.toString());
      selSubject = selPublish = selTerm = selChapter = null;
      chapters = [];
      log = '已加载 ${subjects.length} 个科目';
    });
  }

  Future<void> _loadChapters() async {
    if (selTerm == null) return;
    await _guard(() async {
      chapters = await EebbkApi.getChapters(selTerm!.bookId.toString());
      selChapter = null;
      log = '已加载 ${chapters.length} 个章节';
    });
  }

  // 收集所有叶子章节
  List<Chapter> _leafChapters(List<Chapter> list) {
    final out = <Chapter>[];
    for (var c in list) {
      if (c.childList.isEmpty) {
        out.add(c);
      } else {
        out.addAll(_leafChapters(c.childList));
      }
    }
    return out;
  }

  Future<void> _loadQuestions() async {
    if (selChapter == null || selSubject == null || selTerm == null) {
      setState(() => log = '请先选择完整的年级 / 科目 / 出版社 / 学期 / 章节');
      return;
    }
    setState(() => loading = true);
    try {
      final angleIds = <int>{};
      void collect(List<Chapter> list) {
        for (var c in list) {
          angleIds.addAll(c.examineAngleIds);
          collect(c.childList);
        }
      }

      collect([selChapter!]);
      final questions = await EebbkApi.getQuestions(
        bookId: selTerm!.bookId.toString(),
        chapterId: selChapter!.chapterId.toString(),
        chapterName: selChapter!.chapterName,
        subjectId: selSubject!.subjectId.toString(),
        subjectName: selSubject!.subjectName,
        examineAngleIds: angleIds.toList(),
      );
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() => log = '该章节暂无题目');
      } else {
        setState(() {
          log = '拉到 ${questions.length} 题';
          loading = false;
        });
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => QuestionDeck(questions: questions)),
        );
      }
    } catch (e) {
      if (mounted) setState(() => log = '拉题失败: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            hint: Text(hint),
            value: value,
            borderRadius: BorderRadius.circular(16),
            items: items
                .map((e) => DropdownMenuItem<T>(value: e, child: Text(label(e))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('好题精练'), centerTitle: true),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _dropdown<Grade>(
                hint: '选择年级',
                value: selGrade,
                items: grades.expand((g) => g.grades).toList(),
                label: (g) => g.name,
                onChanged: (g) {
                  selGrade = g;
                  _loadBooks();
                },
              ),
              _dropdown<Subject>(
                hint: '选择科目',
                value: selSubject,
                items: subjects,
                label: (s) => s.subjectName,
                onChanged: (s) {
                  selSubject = s;
                  selPublish = selTerm = selChapter = null;
                  setState(() {});
                },
              ),
              _dropdown<Publish>(
                hint: '选择出版社',
                value: selPublish,
                items: selSubject?.publishList ?? [],
                label: (p) => p.publishName,
                onChanged: (p) {
                  selPublish = p;
                  selTerm = selChapter = null;
                  setState(() {});
                },
              ),
              _dropdown<Term>(
                hint: '选择学期 / 书本',
                value: selTerm,
                items: selPublish?.termList ?? [],
                label: (t) => '${t.termName} ${t.bookName}',
                onChanged: (t) {
                  selTerm = t;
                  _loadChapters();
                },
              ),
              _dropdown<Chapter>(
                hint: '选择章节',
                value: selChapter,
                items: _leafChapters(chapters),
                label: (c) => c.chapterName,
                onChanged: (c) {
                  selChapter = c;
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('开始刷题'),
              ),
              const SizedBox(height: 14),
              Text(log, style: TextStyle(color: cs.outline)),
            ],
          ),
          if (loading)
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: IgnorePointer(child: Center(child: _LoadingBadge())),
            ),
        ],
      ),
    );
  }
}

/// MD3 风格的非阻塞加载角标：不规则图形持续变换
class _LoadingBadge extends StatelessWidget {
  const _LoadingBadge();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 3,
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MorphBlobLoader(size: 26, color: cs.primary),
            const SizedBox(width: 12),
            const Text('加载中…'),
          ],
        ),
      ),
    );
  }
}

/// 不规则图形（blob）加载动画：多个正弦叠加驱动形状持续变换 + 缓慢旋转
class MorphBlobLoader extends StatefulWidget {
  final double size;
  final Color color;
  const MorphBlobLoader({super.key, this.size = 48, required this.color});
  @override
  State<MorphBlobLoader> createState() => _MorphBlobLoaderState();
}

class _MorphBlobLoaderState extends State<MorphBlobLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) =>
            CustomPaint(painter: _BlobPainter(_c.value, widget.color)),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  final Color color;
  _BlobPainter(this.t, this.color);

  static const double _tau = 6.283185307179586;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.width / 2 - 1.5;
    const n = 9;
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = i / n * _tau;
      // 多频正弦叠加：形状不规则且随时间平滑变换
      final wobble = 0.16 * math.sin(3 * a + t * _tau) +
          0.09 * math.sin(5 * a - t * _tau * 1.4) +
          0.05 * math.cos(2 * a + t * _tau * 0.7);
      final r = base * (0.84 + wobble);
      pts.add(center + Offset(math.cos(a) * r, math.sin(a) * r));
    }

    // Catmull-Rom -> 三次贝塞尔，得到平滑闭合曲线
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[(i + 2) % n];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    path.close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * _tau * 0.15);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawShadow(path, color.withAlpha(80), 2, true);
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withAlpha(150)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t || old.color != color;
}

/// 一题一屏：整屏 PageView，可左右滑动 / 按钮切换
class QuestionDeck extends StatefulWidget {
  final List<Question> questions;
  const QuestionDeck({super.key, required this.questions});
  @override
  State<QuestionDeck> createState() => _QuestionDeckState();
}

class _QuestionDeckState extends State<QuestionDeck> {
  final _pc = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final target = _index + delta;
    if (target < 0 || target >= widget.questions.length) return;
    _pc.animateToPage(target,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.questions.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('好题精练 · ${_index + 1}/$total'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: total,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => QuestionPage(q: widget.questions[i]),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _index == 0 ? null : () => _go(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('上一题'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${_index + 1}/$total',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _index == total - 1 ? null : () => _go(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('下一题'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionPage extends StatefulWidget {
  final Question q;
  const QuestionPage({super.key, required this.q});
  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage>
    with AutomaticKeepAliveClientMixin {
  static const _letters = ['A', 'B', 'C', 'D'];
  String? _ans;
  bool _revealed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final q = widget.q;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final opts = (q.options ?? []).take(4).toList();
    final correct = _ans != null &&
        _ans!.toUpperCase() == (q.questionAnswer ?? '').toUpperCase();
    final analysis =
        q.questionAnalysis ?? q.questionAnalyse ?? q.questionComment ?? '无';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '难度 ${q.difficulty ?? '-'}   作答 ${q.answerCount ?? 0}   答对 ${q.rightCount ?? 0}',
            style: tt.labelMedium?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 12),
          Html(
            data: q.questionTitle ?? '',
            style: {
              'body': Style(
                fontSize: FontSize(20),
                lineHeight: LineHeight.number(1.7),
                color: cs.onSurface,
              ),
            },
          ),
          const SizedBox(height: 24),
          ...List.generate(
            opts.isEmpty ? 4 : opts.length,
            (i) => _optionTile(
              _letters[i],
              opts.isEmpty ? null : opts[i],
              _ans == _letters[i],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _ans == null ? null : () => setState(() => _revealed = true),
              child: const Text('提交 / 看答案'),
            ),
          ),
          if (_revealed) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ans == null
                        ? '正确答案：${q.questionAnswer ?? '-'}'
                        : (correct
                            ? '✅ 答对'
                            : '❌ 答错（正确答案：${q.questionAnswer ?? '-'}）'),
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _ans == null
                          ? cs.onSurface
                          : (correct ? Colors.green.shade700 : cs.error),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('解析', style: tt.titleSmall),
                  const SizedBox(height: 6),
                  Html(
                    data: analysis,
                    style: {
                      'body': Style(
                        fontSize: FontSize(17),
                        lineHeight: LineHeight.number(1.6),
                        color: cs.onSurface,
                      ),
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionTile(String letter, String? text, bool selected) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _ans = letter),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: selected ? cs.primary : cs.surface,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: text == null
                      ? const SizedBox.shrink()
                      : Text(text,
                          style: const TextStyle(fontSize: 18, height: 1.4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
