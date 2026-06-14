import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/video_provider.dart';
import '../../models/video_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    final token = context.read<AuthProvider>().token;
    context.read<VideoProvider>().pesquisar(query, token: token);
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VideoProvider>();
    final videos = vp.videos;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        title: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white),
          onChanged: _search,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: 'Pesquisar ocorrências...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                    onPressed: () {
                      _searchCtrl.clear();
                      _search('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtro por categoria
          if (vp.categorias.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _Chip(
                    label: 'Todos',
                    selected: vp.categoriaFiltro == null,
                    onTap: () => vp.setCategoria(null, token: context.read<AuthProvider>().token),
                  ),
                  ...vp.categorias.map((c) => _Chip(
                        label: c.label,
                        selected: vp.categoriaFiltro == c.id,
                        onTap: () => vp.setCategoria(c.id, token: context.read<AuthProvider>().token),
                      )),
                ],
              ),
            ),

          // Resultados
          Expanded(
            child: vp.loading && videos.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : videos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, color: Colors.white24, size: 64),
                            const SizedBox(height: 12),
                            Text(
                              _searchCtrl.text.isEmpty
                                  ? 'Pesquise por título ou localização'
                                  : 'Sem resultados para "${_searchCtrl.text}"',
                              style: const TextStyle(color: Colors.white38),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 9 / 16,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: videos.length,
                        itemBuilder: (_, i) => _VideoThumb(video: videos[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _VideoThumb extends StatelessWidget {
  final VideoModel video;
  const _VideoThumb({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            video.fullThumbnailUrl != null
                ? Image.network(
                    video.fullThumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.white10,
                      child: const Icon(Icons.play_circle_outline, color: Colors.white38, size: 40),
                    ),
                  )
                : Container(
                    color: Colors.white10,
                    child: const Icon(Icons.play_circle_outline, color: Colors.white38, size: 40),
                  ),
            // Gradiente
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
            // Info
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.titulo,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 12),
                      const SizedBox(width: 2),
                      Text('${video.likes}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(width: 8),
                      const Icon(Icons.remove_red_eye, color: Colors.white54, size: 12),
                      const SizedBox(width: 2),
                      Text('${video.visualizacoes}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            if (video.categoriaNome != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(video.categoriaNome!, style: const TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 12)),
      ),
    );
  }
}
