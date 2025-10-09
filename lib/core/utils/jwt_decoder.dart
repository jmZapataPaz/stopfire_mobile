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

  static Map<String, dynamic> decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};
      final payloadJson = _base64UrlDecode(parts[1]);
      final decoded = json.decode(payloadJson);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {};
    } catch (_) {
      return {};
    }
  }

  static String _base64UrlDecode(String input) {
    var s = input.replaceAll('-', '+').replaceAll('_', '/');
    final pad = s.length % 4;
    if (pad > 0) s += '=' * (4 - pad);
    return utf8.decode(base64.decode(s));
  }
}