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
}
