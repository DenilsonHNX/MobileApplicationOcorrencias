import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/video_provider.dart';
import '../../widgets/video_player_item.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeed());
  }

  void _loadFeed() {
    final token = context.read<AuthProvider>().token;
    final vp = context.read<VideoProvider>();
    vp.loadCategorias();
    vp.loadFeed(token: token, refresh: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vp = context.watch<VideoProvider>();

    if (vp.loading && vp.videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    if (vp.videos.isEmpty && !vp.loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              const Text('Sem vídeos de momento.', style: TextStyle(color: Colors.white54, fontSize: 16)),
              if (vp.erroFeed != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(vp.erroFeed!, style: const TextStyle(color: Colors.redAccent, fontSize: 11), textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFeed,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _buildCategoriaFilter(vp, auth.token),
        actions: [
          if (!auth.isAuthenticated)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Entrar', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: vp.videos.length + (vp.hasMore ? 1 : 0),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          if (index >= vp.videos.length - 2) {
            vp.loadFeed(token: auth.token);
          }
        },
        itemBuilder: (context, index) {
          if (index >= vp.videos.length) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          return VideoPlayerItem(
            video: vp.videos[index],
            index: index,
            isActive: index == _currentIndex,
          );
        },
      ),
    );
  }

  Widget _buildCategoriaFilter(VideoProvider vp, String? token) {
    if (vp.categorias.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: 'Todos',
            selected: vp.categoriaFiltro == null,
            onTap: () => vp.setCategoria(null, token: token),
          ),
          ...vp.categorias.map((c) => _CategoryChip(
                label: c.label,
                selected: vp.categoriaFiltro == c.id,
                onTap: () => vp.setCategoria(c.id, token: token),
              )),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 13)),
      ),
    );
  }
}
