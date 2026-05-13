import 'package:flutter/material.dart';
import '../services/spotify_service.dart';
import '../theme/colors.dart';

class SpotifySearchWidget extends StatefulWidget {
  final SpotifyTrack? initialTrack;
  final ValueChanged<SpotifyTrack?> onTrackSelected;

  const SpotifySearchWidget({
    super.key,
    this.initialTrack,
    required this.onTrackSelected,
  });

  @override
  State<SpotifySearchWidget> createState() => _SpotifySearchWidgetState();
}

class _SpotifySearchWidgetState extends State<SpotifySearchWidget> {
  final SpotifyService _spotify = SpotifyService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<SpotifyTrack> _results = [];
  SpotifyTrack? _selectedTrack;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTrack = widget.initialTrack;
  }

  Future<void> _search() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await _spotify.searchTracks(_searchCtrl.text.trim());
      setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al buscar: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectTrack(SpotifyTrack track) {
    setState(() {
      _selectedTrack = track;
      _results = [];
      _searchCtrl.clear();
    });
    widget.onTrackSelected(track);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          children: [
            const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 18),
            const SizedBox(width: 6),
            const Text(
              'Canción en Spotify',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Canción seleccionada actualmente
        if (_selectedTrack != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1DB954), width: 1),
            ),
            child: Row(
              children: [
                if (_selectedTrack!.albumImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      _selectedTrack!.albumImageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTrack!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _selectedTrack!.artistName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: () {
                    setState(() => _selectedTrack = null);
                    widget.onTrackSelected(null);
                  },
                  tooltip: 'Quitar canción',
                ),
              ],
            ),
          ),

        // Campo de búsqueda
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Buscar canción...',
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
                backgroundColor: const Color(0xFF1DB954),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
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

        // Lista de resultados
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final track = _results[index];
                return ListTile(
                  dense: true,
                  leading: track.albumImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            track.albumImageUrl!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.album),
                  title: Text(
                    track.name,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artistName,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: track.previewUrl != null
                      ? const Icon(
                          Icons.headphones,
                          size: 16,
                          color: Color(0xFF1DB954),
                        )
                      : const Tooltip(
                          message: 'Sin preview disponible',
                          child: Icon(
                            Icons.headphones_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                  onTap: () => _selectTrack(track),
                );
              },
            ),
          ),
      ],
    );
  }
}
