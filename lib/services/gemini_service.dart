import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String? buildingName;

  static const String _serverIp = '192.168.1.13';
  static const String _endpoint = 'http://$_serverIp:8000/api/resident-chat';

  GeminiService({this.buildingName});

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'building_name': buildingName ?? 'Copropiedad',
          'message': message,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'] ?? 'Sin respuesta del asistente.';
      } else {
        return 'Error del servidor (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      return 'No se pudo conectar con el servidor ($e). Verifica que el teléfono y el PC sigan en el mismo Wi-Fi.';
    }
  }

  void resetChat() {}
}