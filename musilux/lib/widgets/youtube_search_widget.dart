import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/youtube_service.dart';

class YoutubeSearchWidget extends StatefulWidget {
  final YoutubeVideo? initialVideo;
  final ValueChanged<YoutubeVideo?> onVideoSelected;

  const YoutubeSearchWidget({
    super.key,
    this.initialVideo,
    required this.onVideoSelected,
  });

  @override
  State<YoutubeSearchWidget> createState() => _YoutubeSearchWidgetState();
}

class _YoutubeSearchWidgetState extends State<YoutubeSearchWidget> {
  final YoutubeService _youtube = YoutubeService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<YoutubeVideo> _results = [];
  YoutubeVideo? _selected;
  bool _isLoading = false;
  String? _errorMsg;

  static const _ytRed = Color(0xFFFF0000);

  @override
  void initState() {
    super.initState();
    _selected = widget.initialVideo;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final results = await _youtube.searchVideos(_searchCtrl.text.trim());
      if (mounted) setState(() => _results = results);
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _errorMsg = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectVideo(YoutubeVideo video) {
    setState(() {
      _selected = video;
      _results = [];
      _searchCtrl.clear();
      _errorMsg = null;
    });
    widget.onVideoSelected(video);
  }

  void _clearVideo() {
    setState(() => _selected = null);
    widget.onVideoSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),

        // Header
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: _ytRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, size: 11, color: Colors.white),
            ),
            const SizedBox(width: 6),
            const Text(
              'Video en YouTube',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Video seleccionado
        if (_selected != null) _buildSelectedCard(_selected!),

        // Campo de búsqueda
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Buscar canción en YouTube...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ytRed,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search, color: Colors.white, size: 18),
            ),
          ],
        ),

        // Error
        if (_errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _errorMsg!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        // Lista de resultados
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final video = _results[index];
                return ListTile(
                  dense: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: video.thumbnail != null
                        ? CachedNetworkImage(
                            imageUrl: video.thumbnail!,
                            width: 56,
                            height: 32,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => Container(
                              width: 56,
                              height: 32,
                              color: Colors.grey[200],
                            ),
                            errorWidget: (ctx, url, err) => Container(
                              width: 56,
                              height: 32,
                              color: Colors.grey[200],
                              child: const Icon(Icons.play_circle_outline, size: 20),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 32,
                            color: Colors.grey[200],
                            child: const Icon(Icons.play_circle_outline, size: 20),
                          ),
                  ),
                  title: Text(
                    video.title,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  subtitle: Text(
                    video.channel,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: _ytRed,
                  ),
                  onTap: () => _selectVideo(video),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedCard(YoutubeVideo video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _ytRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ytRed, width: 1),
      ),
      child: Row(
        children: [
          if (video.thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: video.thumbnail!,
                width: 64,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                Text(
                  video.channel,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: _clearVideo,
            tooltip: 'Quitar video',
          ),
        ],
      ),
    );
  }
}
