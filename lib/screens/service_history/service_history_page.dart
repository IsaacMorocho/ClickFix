import 'package:flutter/material.dart';
import '../rate_service/rate_service_page.dart';
import '../../services/database_service.dart';

class ServiceHistoryPage extends StatefulWidget {
  const ServiceHistoryPage({super.key});

  @override
  State<ServiceHistoryPage> createState() => _ServiceHistoryPageState();
}

class _ServiceHistoryPageState extends State<ServiceHistoryPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

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

    _loadServiceHistory();
  }

  Future<void> _loadServiceHistory() async {
    final userId = DatabaseService.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Cargar servicios completados del cliente
      final services = await DatabaseService.getServices(status: 'completado');
      
      // Filtrar solo los servicios del cliente actual
      final clientServices = services.where((s) {
        final serviceRequest = s['service_requests'] as Map<String, dynamic>?;
        return serviceRequest?['cliente_id'] == userId;
      }).toList();

      // Cargar reseñas del cliente para saber cuáles ya calificó
      final reviews = await DatabaseService.getReviews(autorId: userId);
      final reviewedServiceIds = reviews.map((r) => r['service_id']).toSet();
      
      if (mounted) {
        setState(() {
          _services = clientServices.map((s) {
            final serviceRequest = s['service_requests'] as Map<String, dynamic>?;
            final technician = s['technicians'] as Map<String, dynamic>?;
            final techUser = technician?['users'] as Map<String, dynamic>?;
            final quote = s['quotes'] as Map<String, dynamic>?;
            final isRated = reviewedServiceIds.contains(s['id']);
            
            // Buscar la calificación si existe
            final review = reviews.firstWhere(
              (r) => r['service_id'] == s['id'],
              orElse: () => {},
            );
            
            return {
              ...s,
              'descripcion': serviceRequest?['descripcion_problema'] ?? 'Sin descripción',
              'tecnico_nombre': techUser?['nombre_completo'] ?? 'Técnico',
              'tecnico_foto': techUser?['avatar_url'] ?? 'https://via.placeholder.com/150/555879/FFFFFF?text=T',
              'especialidad': 'Servicio técnico',
              'fecha_completado': s['fecha_fin'] != null ? DateTime.parse(s['fecha_fin']) : DateTime.now(),
              'monto': quote?['monto'] ?? 0,
              'calificado': isRated,
              'calificacion': review['calificacion'],
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar historial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatMoney(int amount) {
    return '\$${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }

  void _rateService(Map<String, dynamic> service) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateServicePage(service: service),
      ),
    );

    if (result == true) {
      setState(() {
        service['calificado'] = true;
        service['calificacion'] = 5; // Simulado
      });
    }
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
          child: _services.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    return _buildServiceCard(_services[index]);
                  },
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Historial de Servicios',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: const Color(0xFF98A1BC).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay servicios completados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aqui apareceran tus servicios finalizados',
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

  Widget _buildServiceCard(Map<String, dynamic> service) {
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
          // Encabezado con tecnico
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF555879), width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    service['tecnico_foto'],
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
                      service['tecnico_nombre'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555879),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      service['especialidad'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF98A1BC),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              // Calificacion o boton
              if (service['calificado'])
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < (service['calificacion'] ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      size: 16,
                      color: const Color(0xFFF39C12),
                    );
                  }),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39C12).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF39C12)),
                  ),
                  child: const Text(
                    'Sin calificar',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF39C12),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 16),
          // Descripcion
          Text(
            service['descripcion'],
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(service['fecha_completado']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF98A1BC),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMoney(service['monto']),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF555879),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
              if (!service['calificado'])
                ElevatedButton.icon(
                  onPressed: () => _rateService(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF555879),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text(
                    'Calificar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
