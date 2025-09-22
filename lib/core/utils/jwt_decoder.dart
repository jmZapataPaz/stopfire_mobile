import 'dart:convert';

class JwtDecoder {
  static Map<String, dynamic> decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final normalized = base64Url.normalize(parts[1]);
    final payload = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(payload) as Map<String, dynamic>;
  }

  static int? getUserIdFromSub(String token) {
    final map = decodePayload(token);
    final sub = map['sub']?.toString();
    return sub == null ? null : int.tryParse(sub);
  }
}