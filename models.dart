// 好题精练 - 数据模型
// 字段名直接对应步步高 socialexercise.eebbk.net 后端返回的真实 JSON。

class Grade {
  final String name;
  final int id;
  Grade({required this.name, required this.id});
  factory Grade.fromJson(Map<String, dynamic> j) =>
      Grade(name: j['name'], id: j['id']);
}

class GradeGroup {
  final String gradeName;
  final List<Grade> grades;
  GradeGroup({required this.gradeName, required this.grades});
  factory GradeGroup.fromJson(Map<String, dynamic> j) => GradeGroup(
        gradeName: j['gradeName'],
        grades: (j['grades'] as List).map((e) => Grade.fromJson(e)).toList(),
      );
}

class Term {
  final String termName;
  final String bookName;
  final int bookId;
  Term({required this.termName, required this.bookName, required this.bookId});
  factory Term.fromJson(Map<String, dynamic> j) => Term(
        termName: j['termName'],
        bookName: j['bookName'],
        bookId: j['bookId'],
      );
}

class Publish {
  final String publishName;
  final List<Term> termList;
  Publish({required this.publishName, required this.termList});
  factory Publish.fromJson(Map<String, dynamic> j) => Publish(
        publishName: j['publishName'],
        termList: (j['termList'] as List).map((e) => Term.fromJson(e)).toList(),
      );
}

class Subject {
  final int subjectId;
  final String subjectName;
  final List<Publish> publishList;
  Subject(
      {required this.subjectId,
      required this.subjectName,
      required this.publishList});
  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        subjectId: j['subjectId'],
        subjectName: j['subjectName'],
        publishList:
            (j['publishList'] as List).map((e) => Publish.fromJson(e)).toList(),
      );
}

class QuestionBox {
  final String questionType;
  final String questionTypeName;
  final int questionCount;
  final List<int> examineAngleIds;
  final List<int> hasVideo;
  QuestionBox(
      {required this.questionType,
      required this.questionTypeName,
      required this.questionCount,
      required this.examineAngleIds,
      required this.hasVideo});
  factory QuestionBox.fromJson(Map<String, dynamic> j) => QuestionBox(
        questionType: j['questionType'],
        questionTypeName: j['questionTypeName'],
        questionCount: j['questionCount'],
        examineAngleIds:
            (j['examineAngleIds'] as List? ?? []).map((e) => e as int).toList(),
        hasVideo: (j['hasVideo'] as List? ?? []).map((e) => e as int).toList(),
      );
}

class Chapter {
  final int chapterId;
  final String chapterName;
  final List<Chapter> childList;
  final List<int> examineAngleIds;
  final List<QuestionBox> questionBox;
  Chapter(
      {required this.chapterId,
      required this.chapterName,
      required this.childList,
      required this.examineAngleIds,
      required this.questionBox});
  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        chapterId: j['chapterId'],
        chapterName: j['chapterName'],
        childList: (j['childList'] as List? ?? [])
            .map((e) => Chapter.fromJson(e))
            .toList(),
        examineAngleIds:
            (j['examineAngleIds'] as List? ?? []).map((e) => e as int).toList(),
        questionBox: (j['questionBox'] as List? ?? [])
            .map((e) => QuestionBox.fromJson(e))
            .toList(),
      );
}

class Question {
  final int questionId;
  final String? questionTitle; // 题干 (HTML, 含 MathML)
  final String? questionAnswer; // 正确答案 (选择题为字母, 如 "b")
  final String? questionAnalyse; // 解析 (HTML, 简版)
  final String? questionAnalysis; // 解析 (HTML, 详版)
  final String? questionComment; // 点评 (HTML)
  final String? questionType;
  final num? difficulty;
  final int? answerCount;
  final int? rightCount;
  final int? isCollection;
  final String? score;
  final List<int>? examineAngleIds;
  final List<String>? examAngleName;
  final List<String>? options; // 部分题型有独立选项数组, 字段名待确认

  Question(
      {required this.questionId,
      this.questionTitle,
      this.questionAnswer,
      this.questionAnalyse,
      this.questionAnalysis,
      this.questionComment,
      this.questionType,
      this.difficulty,
      this.answerCount,
      this.rightCount,
      this.isCollection,
      this.score,
      this.examineAngleIds,
      this.examAngleName,
      this.options});

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        questionId: j['questionId'],
        questionTitle: j['questionTitle'],
        questionAnswer: j['questionAnswer'],
        questionAnalyse: j['questionAnalyse'],
        questionAnalysis: j['questionAnalysis'],
        questionComment: j['questionComment'],
        questionType: j['questionType'],
        difficulty: j['difficulty'],
        answerCount: j['answerCount'],
        rightCount: j['rightCount'],
        isCollection: j['isCollection'],
        score: j['score']?.toString(),
        examineAngleIds:
            (j['examineAngleIds'] as List? ?? []).map((e) => e as int).toList(),
        examAngleName: (j['examAngleName'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
        options: _parseOptions(j),
      );

  static List<String>? _parseOptions(Map<String, dynamic> j) {
    for (var k in ['options', 'questionOptions', 'optionList', 'option']) {
      if (j[k] is List) {
        return (j[k] as List).map((e) => e.toString()).toList();
      }
    }
    return null;
  }

  /// 服务端 questionAnswer 可能是 HTML，例如
  /// `<p><question_answer_item></question_answer_item></p><p>D</p><p></p>`。
  /// 这里先去掉标签，再归一化为排序后的字母串（如 "D" / "ABD"），
  /// 用于判分与展示，避免把 HTML 当成答案导致答对被判错。
  String get answerLetters {
    final raw = questionAnswer ?? '';
    if (raw.trim().isEmpty) return '';
    final text = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final set = <String>{};
    for (final m in RegExp(r'[A-Da-d]').allMatches(text)) {
      set.add(m.group(0)!.toUpperCase());
    }
    if (set.isEmpty) return text.trim().toUpperCase();
    final list = set.toList()..sort();
    return list.join();
  }

  /// 选项列表：优先用独立 options 字段；否则从题干内嵌的 input 标签中解析，
  /// 并去掉开头的 “A.” 这类标号（字母由 UI 单独给出）。
  List<String> get optionList => _parseContent(this).options;

  /// 去掉内嵌选项后的题干 HTML（保留图片与公式）。
  String get stemHtml => _parseContent(this).stem;

  /// 把题干拆成 (题干, 选项)。
  ///
  /// 服务端的选项写法有两种：
  ///   1) `<input ...>A.…</input>`（带闭合标签）
  ///   2) `<input .../>A.…`（自闭合，无闭合标签，选项内容紧跟其后）
  /// 因此以“开标签 <input …>”作为切分点：每段从某个 input 标签结束到下一个
  /// input 标签（或末尾），即为一个选项；这段里的 </input>、<p>/</p> 一并去掉。
  /// 这样无论属性顺序、引号、是否自闭合都能正确解析，不会再把选项留在题干里。
  static _Content _parseContent(Question q) {
    final title = q.questionTitle ?? '';
    final openRe = RegExp(r'<input\b[^>]*>', caseSensitive: false);
    final opens = openRe.allMatches(title).toList();

    String stem = title;
    final parsed = <String>[];
    if (opens.isNotEmpty) {
      stem = title.substring(0, opens.first.start);
      for (var i = 0; i < opens.length; i++) {
        final start = opens[i].end;
        final end = i + 1 < opens.length ? opens[i + 1].start : title.length;
        parsed.add(_cleanOption(title.substring(start, end)));
      }
      // 末尾可能残留一个空的 <p>（选项所在段落的开标签），去掉
      stem = stem
          .replaceFirst(RegExp(r'(\s*<p\b[^>]*>\s*)+$', caseSensitive: false),
              '')
          .trim();
    }

    final opts =
        (q.options != null && q.options!.isNotEmpty) ? q.options! : parsed;
    return _Content(stem, opts);
  }

  static String _cleanOption(String s) {
    var v = s
        .replaceAll(RegExp(r'</?input\b[^>]*>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'</?p\b[^>]*>', caseSensitive: false), ' ')
        .trim();
    // 去掉开头的选项标号：A. / B、/ C．/ D)
    v = v.replaceFirst(RegExp(r'^[A-Da-d]\s*[.、．,，:：)）]\s*'), '');
    return v.trim();
  }
}

class _Content {
  final String stem;
  final List<String> options;
  const _Content(this.stem, this.options);
}
