import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';

class SpotifyTrack {
  final String id;
  final String name;
  final String artistName;
  final String albumName;
  final String? previewUrl;
  final String? albumImageUrl;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumName,
    this.previewUrl,
    this.albumImageUrl,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: json['id'],
      name: json['name'],
      artistName: json['artist_name'],
      albumName: json['album_name'],
      previewUrl: json['preview_url'],
      albumImageUrl: json['album_image_url'],
    );
  }
}

class SpotifyService {
  // Usa el mismo base URL que el resto de la app.
  // Antes usaba ngrok hardcodeado → el navegador recibía la página de
  // advertencia de ngrok (HTML) en lugar de JSON → fallo silencioso en Web.
  String get _baseUrl => ApiConstants.baseUrl;

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    final uri = Uri.parse('$_baseUrl/spotify/search')
        .replace(queryParameters: {'q': query});

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['tracks'] as List;
      return items.map((item) => SpotifyTrack.fromJson(item)).toList();
    } else {
      throw Exception('Error en búsqueda Spotify: ${response.statusCode}');
    }
  }
}
