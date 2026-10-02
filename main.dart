// 好题精练精简版 - 最小可用 UI（原生渲染，不用 WebView，治卡顿）
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'api.dart';
import 'models.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '好题精练精简版',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _accCtl =
      TextEditingController(text: EebbkApi.accountId);
  List<GradeGroup> grades = [];
  List<Subject> subjects = [];
  List<Chapter> chapters = [];
  List<Question> questions = [];
  Grade? selGrade;
  Subject? selSubject;
  Publish? selPublish;
  Term? selTerm;
  Chapter? selChapter;
  bool loading = false;
  String log = '';

  @override
  void initState() {
    super.initState();
    _accCtl.addListener(() => EebbkApi.accountId = _accCtl.text);
    _loadGrades();
  }

  @override
  void dispose() {
    _accCtl.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    setState(() => loading = true);
    try {
      grades = await EebbkApi.getGrades();
    } catch (e) {
      log = '加载年级失败: $e';
    }
    setState(() => loading = false);
  }

  Future<void> _loadBooks() async {
    if (selGrade == null) return;
    setState(() => loading = true);
    try {
      subjects = await EebbkApi.getBooks(selGrade!.id.toString());
    } catch (e) {
      log = '加载书本失败: $e';
    }
    selSubject = selPublish = selTerm = selChapter = null;
    chapters = [];
    setState(() => loading = false);
  }

  Future<void> _loadChapters() async {
    if (selTerm == null) return;
    setState(() => loading = true);
    try {
      chapters = await EebbkApi.getChapters(selTerm!.bookId.toString());
    } catch (e) {
      log = '加载章节失败: $e';
    }
    selChapter = null;
    setState(() => loading = false);
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
    if (selChapter == null || selSubject == null || selTerm == null) return;
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
      questions = await EebbkApi.getQuestions(
        bookId: selTerm!.bookId.toString(),
        chapterId: selChapter!.chapterId.toString(),
        chapterName: selChapter!.chapterName,
        subjectId: selSubject!.subjectId.toString(),
        subjectName: selSubject!.subjectName,
        examineAngleIds: angleIds.toList(),
      );
      log = '拉到 ${questions.length} 题';
    } catch (e) {
      log = '拉题失败: $e';
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('好题精练精简版')),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  TextField(
                    controller: _accCtl,
                    decoration:
                        const InputDecoration(labelText: 'accountId（你的步步高账号）'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<Grade>(
                    hint: const Text('选择年级'),
                    value: selGrade,
                    items: grades
                        .expand<Grade>((g) => g.grades)
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text(g.name)))
                        .toList(),
                    onChanged: (g) {
                      selGrade = g;
                      _loadBooks();
                    },
                  ),
                  DropdownButton<Subject>(
                    hint: const Text('选择科目'),
                    value: selSubject,
                    items: subjects
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.subjectName)))
                        .toList(),
                    onChanged: (s) {
                      selSubject = s;
                      selPublish = selTerm = selChapter = null;
                      setState(() {});
                    },
                  ),
                  DropdownButton<Publish>(
                    hint: const Text('选择出版社'),
                    value: selPublish,
                    items: (selSubject?.publishList ?? [])
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p.publishName)))
                        .toList(),
                    onChanged: (p) {
                      selPublish = p;
                      selTerm = selChapter = null;
                      setState(() {});
                    },
                  ),
                  DropdownButton<Term>(
                    hint: const Text('选择学期 / 书本'),
                    value: selTerm,
                    items: (selPublish?.termList ?? [])
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t.termName} ${t.bookName}')))
                        .toList(),
                    onChanged: (t) {
                      selTerm = t;
                      _loadChapters();
                    },
                  ),
                  DropdownButton<Chapter>(
                    hint: const Text('选择章节'),
                    value: selChapter,
                    items: _leafChapters(chapters)
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.chapterName)))
                        .toList(),
                    onChanged: (c) {
                      selChapter = c;
                      setState(() {});
                    },
                  ),
                  ElevatedButton(
                      onPressed: _loadQuestions, child: const Text('开始刷题')),
                  Text(log, style: const TextStyle(color: Colors.grey)),
                  const Divider(),
                  ...questions.map((q) => QuestionCard(q: q)),
                ],
              ),
      );
}

class QuestionCard extends StatefulWidget {
  final Question q;
  const QuestionCard({super.key, required this.q});
  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  String? myAns;
  bool showAns = false;
  final choices = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    final correct = myAns != null &&
        myAns!.toUpperCase() == (q.questionAnswer ?? '').toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '题号 ${q.questionId}  难度 ${q.difficulty ?? '-'}  '
                '作答 ${q.answerCount ?? 0}  答对 ${q.rightCount ?? 0}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Html(data: q.questionTitle ?? ''),
            const SizedBox(height: 6),
            // 若服务端返回独立选项数组则渲染选项，否则用 A-F 手动判分
            if (q.options != null && q.options!.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: q.options!.asMap().entries.map((e) {
                  final letter = choices[e.key];
                  return ChoiceChip(
                    label: Text('$letter. ${e.value}'),
                    selected: myAns == letter,
                    onSelected: (_) => setState(() => myAns = letter),
                  );
                }).toList(),
              )
            else
              Wrap(
                spacing: 6,
                children: choices.take(6).map((c) {
                  return ChoiceChip(
                    label: Text(c),
                    selected: myAns == c,
                    onSelected: (_) => setState(() => myAns = c),
                  );
                }).toList(),
              ),
            ElevatedButton(
                onPressed: () => setState(() => showAns = true),
                child: const Text('提交 / 看答案')),
            if (showAns) ...[
              if (myAns != null)
                Text(
                    correct
                        ? '✅ 答对'
                        : '❌ 答错（正确答案：${q.questionAnswer}）',
                    style: TextStyle(
                        color: correct ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('解析：', style: TextStyle(fontWeight: FontWeight.bold)),
              Html(data: q.questionAnalysis ?? q.questionAnalyse ?? q.questionComment ?? '无'),
            ],
          ],
        ),
      ),
    );
  }
}
