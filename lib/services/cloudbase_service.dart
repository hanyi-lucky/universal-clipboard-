import 'dart:convert';
import 'package:http/http.dart' as http;

/// 腾讯云开发 — 通过云函数 HTTP 端点访问
class CloudBaseService {
  static const _functionUrl =
      'https://universal-clipboard-d7b1c6cd31bc-1446090713.ap-shanghai.app.tcloudbase.com/api';

  String? _openId;

  String? get openId => _openId;
  bool get isLoggedIn => _openId != null;

  /// 匿名登录（生成设备 ID）
  Future<void> signInAnonymously() async {
    // 云函数不需要真正的登录，用设备标识代替
    _openId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 调用云函数
  Future<Map<String, dynamic>> _callFunction(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final result = jsonDecode(response.body);
    return result;
  }

  /// 创建文档
  Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    final result = await _callFunction({
      'action': 'addDocument',
      'collection': collection,
      'data': jsonEncode(data),
    });

    if (result['code'] != 'SUCCESS') {
      throw Exception('addDocument failed: ${result['message']}');
    }

    return result['id'] as String;
  }

  /// 设置文档（覆盖或创建）
  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    final result = await _callFunction({
      'action': 'setDocument',
      'collection': collection,
      'docId': docId,
      'data': jsonEncode(data),
    });

    if (result['code'] != 'SUCCESS') {
      throw Exception('setDocument failed: ${result['message']}');
    }
  }

  /// 获取文档
  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    final result = await _callFunction({
      'action': 'getDocument',
      'collection': collection,
      'docId': docId,
    });

    if (result['code'] == 'NOT_FOUND') return null;
    if (result['code'] != 'SUCCESS') return null;

    final dataStr = result['data'] as String?;
    if (dataStr == null) return null;
    return jsonDecode(dataStr) as Map<String, dynamic>;
  }

  /// 查询文档列表
  Future<List<Map<String, dynamic>>> queryDocuments(
    String collection, {
    Map<String, dynamic>? filter,
    String? orderBy,
    bool descending = false,
    int limit = 100,
  }) async {
    final result = await _callFunction({
      'action': 'queryDocuments',
      'collection': collection,
      'filter': filter != null ? jsonEncode(filter) : null,
      'orderBy': orderBy,
      'descending': descending,
      'limit': limit,
    });

    if (result['code'] != 'SUCCESS') return [];

    final records = result['data']['records'] as List? ?? [];
    return records.map((r) {
      final dataStr = r['data'] as String? ?? '{}';
      final parsed = jsonDecode(dataStr) as Map<String, dynamic>;
      parsed['id'] = r['id'];
      return parsed;
    }).toList();
  }

  /// 更新文档
  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    final result = await _callFunction({
      'action': 'updateDocument',
      'collection': collection,
      'docId': docId,
      'data': jsonEncode(data),
    });

    if (result['code'] != 'SUCCESS') {
      throw Exception('updateDocument failed: ${result['message']}');
    }
  }

  /// 删除文档
  Future<void> deleteDocument(String collection, String docId) async {
    final result = await _callFunction({
      'action': 'deleteDocument',
      'collection': collection,
      'docId': docId,
    });

    if (result['code'] != 'SUCCESS') {
      throw Exception('deleteDocument failed: ${result['message']}');
    }
  }
}
