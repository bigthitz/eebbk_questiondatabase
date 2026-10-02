// 好题精练 - 网络层
// 对应步步高 socialexercise.eebbk.net 的真实接口（已抓包还原）。
// 鉴权极弱：仅需 accountId + 设备伪装参数，无 sign / token。

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class EebbkApi {
  static const String base = 'https://socialexercise.eebbk.net';
  static const String path = '/examination/question';

  // 你的步步高账号 ID（自用，直接填自己的；原版就是靠它鉴权）
  static String accountId = '157749558';

  // 设备伪装参数（原版好题精练在 S6 学习机上的标识）
  static const Map<String, String> _device = {
    'apkVersionName': '2.10.5.0.H',
    'machineId': '',
    'apkPackageName': 'com.eebbk.questiondatabase',
    'apkVersionCode': '2100500',
    'deviceModel': 'S6',
    'deviceOSVersion': 'V4.0.0_250905',
    'machineType': '1',
  };

  // 注意：不要在这里写 Accept-Encoding，交给 http 包自动处理
  static Map<String, String> _headers() => {
        'accountId': accountId,
        ..._device,
        'timestamp': _now(),
        'Accept-Http': 'https',
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'okhttp/3.12.0',
      };

  static String _now() {
    final d = DateTime.now();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${p(d.month)}-${p(d.day)} '
        '${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
  }

  // 统一 POST：header 与 body 都带 accountId + 设备参数（与原版一致）
  static Future<Map<String, dynamic>> _post(
      String ep, Map<String, String> body) async {
    final uri = Uri.parse('$base$path/$ep');
    final resp = await http.post(
      uri,
      headers: _headers(),
      body: {..._device, ...body, 'accountId': accountId},
    );

    // http 包已自动处理 gzip，这里直接用 bodyBytes 解码即可
    final text = utf8.decode(resp.bodyBytes, allowMalformed: true);

    // 调试用：需要时取消注释
    // print('[$ep] status=${resp.statusCode} body=$text');

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: $text');
    }

    final jsonMap = json.decode(text) as Map<String, dynamic>;

    final code = jsonMap['errorCode']?.toString();
    if (code != null && code != '101002' && code != '0') {
      throw Exception('接口错误 [$code]: ${jsonMap['errorInfo']}');
    }

    return jsonMap;
  }

  // ① 年级列表
  static Future<List<GradeGroup>> getGrades() async {
    final j = await _post('getBookGradeList', {});
    return (j['data'] as List).map((e) => GradeGroup.fromJson(e)).toList();
  }

  // ② 按年级查书本（出版社 / 学期 / bookId）
  static Future<List<Subject>> getBooks(String gradeCode) async {
    final j = await _post('getBookFilterByGradeCode', {'gradeCode': gradeCode});
    return (j['data'] as List).map((e) => Subject.fromJson(e)).toList();
  }

  // ③ 按书本查章节树（含知识点ID、各题型题量）
  static Future<List<Chapter>> getChapters(String bookId) async {
    final j = await _post('getBookChaptersInfo', {'bookId': bookId});
    return (j['data'] as List).map((e) => Chapter.fromJson(e)).toList();
  }

  // ④ 按章节 + 知识点拉题
  static Future<List<Question>> getQuestions({
    required String bookId,
    required String chapterId,
    required String chapterName,
    required String subjectId,
    required String subjectName,
    required List<int> examineAngleIds,
    String questionType = 'ZHINENGSHUATI',
    String questionTypeName = '智能刷题',
    int size = 5,
  }) async {
    final j = await _post('getWebViewNew', {
      'bookId': bookId,
      'chapterId': chapterId,
      'chapterName': chapterName,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'examineAngleIds': json.encode(examineAngleIds),
      'questionType': questionType,
      'questionTypeName': questionTypeName,
      'size': size.toString(),
    });
    return (j['data']['list'] as List)
        .map((e) => Question.fromJson(e))
        .toList();
  }
}
