import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class ServiceInProgressPage extends StatefulWidget {
  final String? serviceId;

  const ServiceInProgressPage({super.key, this.serviceId});

  @override
  State<ServiceInProgressPage> createState() => _ServiceInProgressPageState();
}

class _ServiceInProgressPageState extends State<ServiceInProgressPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? service;
  Map<String, dynamic>? technician;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
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

    _loadServiceDataFromDatabase();
  }

  Future<void> _loadServiceDataFromDatabase() async {
    try {
      // Si no hay serviceId, obtener servicios en progreso del usuario actual
      final userId = DatabaseService.currentUserId;
      if (userId == null) {
        setState(() {
          service = {};
          technician = {};
        });
        return;
      }

      // Cargar datos del servicio desde Supabase
      final serviceData = await DatabaseService.getServices(
        clientId: userId,
        status: 'en_progreso',
      );

      if (serviceData.isNotEmpty) {
        // Si se proporcionó serviceId, buscar ese servicio específico
        final serviceItem = widget.serviceId != null
            ? serviceData.firstWhere(
                (s) => s['id'] == widget.serviceId,
                orElse: () => serviceData.first,
              )
            : serviceData.first;
        setState(() {
          service = serviceItem;
        });

        // Obtener datos del técnico si existe technician_id
        if (serviceItem['technician_id'] != null) {
          final techProfile = await DatabaseService.getTechnicianProfile(
            serviceItem['technician_id'],
          );

          if (techProfile != null) {
            setState(() {
              technician = {
                'id': techProfile['id'],
                'nombre': techProfile['users']?['nombre_completo'] ?? 'Técnico',
                'especialidad': 'Ver especialidades',
                'foto_url': techProfile['users']?['avatar_url'],
                'teléfono': techProfile['users']?['telefono'] ?? '',
                'email': techProfile['users']?['email'] ?? '',
                'whatsapp': techProfile['users']?['telefono'] ?? '',
                'rating': techProfile['rating_promedio'] ?? 0.0,
                'votos': techProfile['total_reviews'] ?? 0,
              };
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos del servicio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        service = {};
        technician = {};
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
  // MÉTODOS AUXILIARES
  // ========================================================================

  Color _getStateColor(String estado) {
    switch (estado) {
      case 'en_camino':
        return const Color(0xFF3498DB);
      case 'en_progreso':
        return const Color(0xFFF39C12);
      case 'completado':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  IconData _getStateIcon(String estado) {
    switch (estado) {
      case 'en_camino':
        return Icons.directions_car;
      case 'en_progreso':
        return Icons.build;
      case 'completado':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getStateLabel(String estado) {
    switch (estado) {
      case 'en_camino':
        return 'En Camino';
      case 'en_progreso':
        return 'En Progreso';
      case 'completado':
        return 'Completado';
      default:
        return estado;
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 30) {
      return 'Hace ${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _calculateRemainingTime(DateTime endTime) {
    final difference = endTime.difference(DateTime.now());

    if (difference.isNegative) {
      return 'Completado';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m restantes';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m restantes';
    } else {
      return '${difference.inDays}d restantes';
    }
  }

  // ========================================================================
  // CONSTRUIR INTERFAZ
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    // Validar que service y technician estén cargados
    if (service == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4EBD3),
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF555879)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4EBD3),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                _buildStatusSection(),
                const SizedBox(height: 20),
                _buildTechnicianSection(),
                const SizedBox(height: 20),
                _buildScheduleSection(),
                const SizedBox(height: 20),
                _buildProgressSection(),
                const SizedBox(height: 20),
                _buildNotesSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Servicio en Progreso',
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

  /// Sección de estado
  Widget _buildStatusSection() {
    final stateColor = _getStateColor(service!['estado']);
    final stateIcon = _getStateIcon(service!['estado']);
    final stateLabel = _getStateLabel(service!['estado']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: stateColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stateColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: stateColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(stateIcon, size: 56, color: stateColor),
          const SizedBox(height: 12),
          Text(
            stateLabel,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: stateColor,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _calculateRemainingTime(service!['fecha_fin']),
            style: TextStyle(
              fontSize: 14,
              color: stateColor.withOpacity(0.8),
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de técnico asignado
  Widget _buildTechnicianSection() {
    return _buildSectionContainer(
      icon: Icons.assignment_ind,
      title: 'Técnico Asignado',
      content: Column(
        children: [
          // Avatar y nombre
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF555879).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFF555879),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF555879).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      technician?['foto_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF555879),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  technician?['nombre'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555879),
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  technician?['especialidad'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF98A1BC),
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 18, color: const Color(0xFFF39C12)),
                    const SizedBox(width: 4),
                    Text(
                      '${technician?['rating']} (${technician?['votos']} votos)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF555879),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 20),
          // Contacto
          _buildContactRow(
            icon: Icons.phone,
            label: 'Teléfono',
            value: technician?['teléfono'],
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            icon: Icons.email,
            label: 'Email',
            value: technician?['email'],
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            icon: Icons.chat,
            label: 'WhatsApp',
            value: technician?['whatsapp'],
          ),
        ],
      ),
    );
  }

  /// Fila de contacto
  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EBD3).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF555879), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF98A1BC),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555879),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de cronograma
  Widget _buildScheduleSection() {
    return _buildSectionContainer(
      icon: Icons.schedule,
      title: 'Cronograma',
      content: Column(
        children: [
          // Fecha de inicio
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDED3C4), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF3498DB),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_circle,
                    color: Color(0xFF3498DB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inicio',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF98A1BC),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDateTime(service!['fecha_inicio'])} a las ${_formatTime(service!['fecha_inicio'])}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555879),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Timeline visual
          SizedBox(
            height: 30,
            child: Center(
              child: Container(width: 3, color: const Color(0xFFDED3C4)),
            ),
          ),
          const SizedBox(height: 12),
          // Fecha de fin
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDED3C4), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF27AE60),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF27AE60),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fin estimado',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF98A1BC),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDateTime(service!['fecha_fin'])} a las ${_formatTime(service!['fecha_fin'])}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555879),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de progreso
  Widget _buildProgressSection() {
    final startTime = service!['fecha_inicio'] != null
        ? DateTime.parse(service!['fecha_inicio'].toString())
        : DateTime.now();
    final endTime = service!['fecha_fin'] != null
        ? DateTime.parse(service!['fecha_fin'].toString())
        : DateTime.now().add(const Duration(hours: 2));
    final now = DateTime.now();

    final totalDuration = endTime.difference(startTime).inMinutes;
    final elapsedDuration = now.difference(startTime).inMinutes;
    final progress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);

    return _buildSectionContainer(
      icon: Icons.trending_up,
      title: 'Progreso del Servicio',
      content: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFFDED3C4),
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF555879).withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% completado',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
              ),
              Text(
                _calculateRemainingTime(service!['fecha_fin']),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF98A1BC),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sección de notas del técnico
  Widget _buildNotesSection() {
    return _buildSectionContainer(
      icon: Icons.note,
      title: 'Notas del Técnico',
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EBD3).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDED3C4), width: 1.5),
        ),
        child: Text(
          service!['notas_tecnico'],
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF555879),
            fontFamily: 'Montserrat',
            height: 1.6,
          ),
        ),
      ),
    );
  }

  /// Contenedor de sección reutilizable
  Widget _buildSectionContainer({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
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
          Row(
            children: [
              Icon(icon, color: const Color(0xFF555879), size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}
