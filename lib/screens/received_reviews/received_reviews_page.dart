import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class ReceivedReviewsPage extends StatefulWidget {
  const ReceivedReviewsPage({super.key});

  @override
  State<ReceivedReviewsPage> createState() => _ReceivedReviewsPageState();
}

class _ReceivedReviewsPageState extends State<ReceivedReviewsPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>>? _reviews;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    _loadReviewsFromDatabase();
  }

  Future<void> _loadReviewsFromDatabase() async {
    try {
      // Obtener el ID del técnico actual
      final userId = DatabaseService.currentUserId;
      if (userId == null) {
        setState(() => _reviews = []);
        return;
      }

      // Obtener perfil de técnico
      final techProfile = await DatabaseService.getTechnicianProfile(userId);
      if (techProfile == null) {
        setState(() => _reviews = []);
        return;
      }

      // Cargar reseñas reales desde Supabase
      final reviewsData = await DatabaseService.getReviews(
        receptorId: techProfile['id'],
      );

      setState(() {
        _reviews = reviewsData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reseñas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _reviews = [];
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ========================================================================
  // METODOS AUXILIARES
  // ========================================================================

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  double get _averageRating {
    if (_reviews?.isEmpty ?? true) return 0;
    final total = _reviews!.fold<int>(
      0,
      (sum, r) => sum + (r['calificacion'] as int),
    );
    return total / _reviews!.length;
  }

  // ========================================================================
  // CONSTRUIR INTERFAZ
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildStatsSection(),
              Expanded(
                child: (_reviews?.isEmpty ?? true)
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _reviews!.length,
                        itemBuilder: (context, index) {
                          return _buildReviewCard(_reviews![index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Mis Resenas',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      backgroundColor: const Color(0xFF555879),
      elevation: 4,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF98A1BC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF555879).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555879),
                    fontFamily: 'Montserrat',
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < _averageRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      size: 20,
                      color: const Color(0xFFF39C12),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_reviews?.length ?? 0} resenas',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF98A1BC),
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 80, color: const Color(0xFFDED3C4)),
          Expanded(
            child: Column(
              children: [
                _buildRatingBar(
                  5,
                  _reviews?.where((r) => r['calificacion'] == 5).length ?? 0,
                ),
                _buildRatingBar(
                  4,
                  _reviews?.where((r) => r['calificacion'] == 4).length ?? 0,
                ),
                _buildRatingBar(
                  3,
                  _reviews?.where((r) => r['calificacion'] == 3).length ?? 0,
                ),
                _buildRatingBar(
                  2,
                  _reviews?.where((r) => r['calificacion'] == 2).length ?? 0,
                ),
                _buildRatingBar(
                  1,
                  _reviews?.where((r) => r['calificacion'] == 1).length ?? 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count) {
    final percentage = (_reviews?.isEmpty ?? true)
        ? 0.0
        : count / (_reviews?.length ?? 1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF98A1BC),
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Color(0xFFF39C12)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFDED3C4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF555879),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF98A1BC),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review,
            size: 80,
            color: const Color(0xFF98A1BC).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes resenas aun',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las resenas de tus clientes apareceran aqui',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF98A1BC).withOpacity(0.7),
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF98A1BC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF555879).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF555879), width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    review['autor_foto'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Color(0xFF555879));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['autor_nombre'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555879),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      review['servicio'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF98A1BC),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (review['calificacion'] as int)
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: const Color(0xFFF39C12),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(review['fecha']),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF98A1BC),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 12),
          // Comentario
          Text(
            review['comentario'],
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
