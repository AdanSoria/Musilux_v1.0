import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_constants.dart';

class YoutubeVideo {
  final String videoId;
  final String title;
  final String channel;
  final String? thumbnail;

  const YoutubeVideo({
    required this.videoId,
    required this.title,
    required this.channel,
    this.thumbnail,
  });

  factory YoutubeVideo.fromJson(Map<String, dynamic> json) {
    return YoutubeVideo(
      videoId: json['video_id'] as String,
      title: json['title'] as String,
      channel: json['channel'] as String,
      thumbnail: json['thumbnail'] as String?,
    );
  }
}

class YoutubeService {
  String get _baseUrl => ApiConstants.baseUrl;

  Future<List<YoutubeVideo>> searchVideos(String query) async {
    final uri = Uri.parse('$_baseUrl/youtube/search')
        .replace(queryParameters: {'q': query});

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['videos'] as List<dynamic>;
      return items
          .map((item) => YoutubeVideo.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (response.statusCode == 503) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error de YouTube API');
    }

    throw Exception('Error en búsqueda YouTube: ${response.statusCode}');
  }
}
