import 'package:flutter/material.dart';
import '../../core/animations/page_transitions.dart';
import '../../services/database_service.dart';

/// Pantalla de técnicos favoritos del cliente
class FavoriteTechniciansPage extends StatefulWidget {
  const FavoriteTechniciansPage({super.key});

  @override
  State<FavoriteTechniciansPage> createState() =>
      _FavoriteTechniciansPageState();
}

class _FavoriteTechniciansPageState extends State<FavoriteTechniciansPage> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      final userId = DatabaseService.currentUserId;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // TODO: Cargar técnicos favoritos desde el backend
      final favorites = await DatabaseService.getFavoriteTechnicians(userId);

      if (mounted) {
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar favoritos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFavorite(String technicianId) async {
    try {
      final userId = DatabaseService.currentUserId;
      if (userId == null) return;

      await DatabaseService.removeFavoriteTechnician(userId, technicianId);

      await _loadFavorites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Técnico removido de favoritos'),
            backgroundColor: Color(0xFF555879),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al remover favorito: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: AppBar(
        title: const Text(
          'Técnicos Favoritos',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF555879),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  return _buildFavoriteCard(_favorites[index], index);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: const Color(0xFF98A1BC).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes técnicos favoritos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Marca como favorito a los técnicos que brindan un excelente servicio',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF98A1BC),
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> technician, int index) {
    return SlideFadeAnimation(
      delay: Duration(milliseconds: 100 * index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF98A1BC)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF555879).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar del técnico
                Hero(
                  tag: 'technician_${technician['id']}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF555879),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        technician['avatar_url'] ??
                            'https://via.placeholder.com/150/555879/FFFFFF?text=${technician['nombre_completo']?[0] ?? 'T'}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 32,
                            color: Color(0xFF555879),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Información del técnico
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              technician['nombre_completo'] ?? 'Técnico',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF555879),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          Icon(
                            Icons.verified,
                            size: 20,
                            color: technician['verificado'] == true
                                ? const Color(0xFF27AE60)
                                : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Color(0xFFF39C12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${technician['rating']?.toStringAsFixed(1) ?? '0.0'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF555879),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${technician['total_servicios'] ?? 0} servicios)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF98A1BC),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        technician['especialidades']?.join(', ') ??
                            'Sin especialidades',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF98A1BC),
                          fontFamily: 'Montserrat',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Enviar solicitud directa al técnico favorito
                      Navigator.pushNamed(
                        context,
                        '/serviceRequestCreate',
                        arguments: {
                          'preferred_technician_id': technician['id'],
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF555879),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_task, size: 18),
                    label: const Text(
                      'Solicitar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text(
                          'Remover de Favoritos',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          '¿Deseas remover a ${technician['nombre_completo']} de tus favoritos?',
                          style: const TextStyle(fontFamily: 'Montserrat'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(fontFamily: 'Montserrat'),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _removeFavorite(technician['id']);
                            },
                            child: const Text(
                              'Remover',
                              style: TextStyle(
                                color: Colors.red,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.favorite, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
