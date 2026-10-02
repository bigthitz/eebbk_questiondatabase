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

  static final RegExp _radioRe = RegExp(
    r'<input\b[^>]*\bclass\s*=\s*"input_radio"[^>]*>(.*?)</input>',
    caseSensitive: false,
    dotAll: true,
  );

  static final RegExp _radioAnyRe = RegExp(
    r'<input\b[^>]*type\s*=\s*"radio"[^>]*>(.*?)</input>',
    caseSensitive: false,
    dotAll: true,
  );

  bool get hasEmbeddedOptions {
    final t = questionTitle ?? '';
    return _radioRe.hasMatch(t) || _radioAnyRe.hasMatch(t);
  }

  /// 选项列表：优先用独立 options 字段；否则从题干内嵌的
  /// `<input type="radio" class="input_radio">A.…</input>` 中解析，
  /// 并去掉开头的 “A.” 这类标号（字母由 UI 单独给出）。
  List<String> get optionList {
    if (options != null && options!.isNotEmpty) return options!;
    final t = questionTitle ?? '';
    var ms = _radioRe.allMatches(t).toList();
    if (ms.isEmpty) ms = _radioAnyRe.allMatches(t).toList();
    return ms.map((m) {
      var v = m.group(1)!.trim();
      v = v.replaceFirst(RegExp(r'^[A-Da-d]\s*[.、．,，:：)）]\s*'), '');
      return v.trim();
    }).toList();
  }

  /// 去掉内嵌选项后的题干 HTML（保留图片与公式）。
  String get stemHtml {
    final t = questionTitle ?? '';
    if (!hasEmbeddedOptions) return t;
    return t.replaceAll(_radioRe, '').replaceAll(_radioAnyRe, '').trim();
  }
}

/// 把 MathML 展平为可读文本。flutter_html 不支持 MathML，直接渲染公式会丢失
/// （表现为空白），这里按 mfrac/msup/msub 等结构转成 num/den、base^exp、
/// base_sub 之类的线性写法，保证内容可见。
String flattenMath(String html) {
  final re =
      RegExp(r'<math\b[^>]*>(.*?)</math>', caseSensitive: false, dotAll: true);
  return html.replaceAllMapped(re, (m) => _renderMathMl(m.group(1)!));
}

class _MmlNode {
  final String tag;
  final List<Object> children = [];
  _MmlNode(this.tag);
}

String _renderMathMl(String inner) {
  final root = _MmlNode('math');
  final stack = <_MmlNode>[root];
  final tokenRe = RegExp(r'</?[a-zA-Z][^>]*>|[^<]+');
  for (final m in tokenRe.allMatches(inner)) {
    final t = m.group(0)!;
    if (t.startsWith('</')) {
      if (stack.length > 1) stack.removeLast();
    } else if (t.startsWith('<')) {
      final name = RegExp(r'^<\s*([a-zA-Z][\w:.-]*)')
              .firstMatch(t)
              ?.group(1)
              ?.toLowerCase() ??
          '';
      final node = _MmlNode(name);
      stack.last.children.add(node);
      if (!t.endsWith('/>')) stack.add(node);
    } else {
      stack.last.children.add(t);
    }
  }
  var out = _serializeMml(root).replaceAll(RegExp(r'\s+'), ' ').trim();
  // 只转义尖括号，保留 &#x2212; 之类的实体交给渲染层解码。
  out = out.replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  return out;
}

String _serializeMml(Object n) {
  if (n is String) return n;
  final node = n as _MmlNode;
  final kids = node.children;
  String k(int i) => i < kids.length ? _serializeMml(kids[i]) : '';
  switch (node.tag) {
    case 'mfrac':
      return '(${k(0)})/(${k(1)})';
    case 'msup':
      return '${k(0)}^${k(1)}';
    case 'msub':
      return '${k(0)}_${k(1)}';
    case 'msubsup':
      return '${k(0)}_${k(1)}^${k(2)}';
    case 'msqrt':
      return '√(${kids.map(_serializeMml).join()})';
    case 'mroot':
      return '${k(0)}√(${k(1)})';
    case 'mover':
      return '${k(0)}${k(1)}';
    default:
      return kids.map(_serializeMml).join();
  }
}
