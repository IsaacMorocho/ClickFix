import 'package:flutter/material.dart';
import '../service_quotations/service_quotations_page.dart';

class ServiceRequestDetailPage extends StatefulWidget {
  final Map<String, dynamic> request;

  const ServiceRequestDetailPage({super.key, required this.request});

  @override
  State<ServiceRequestDetailPage> createState() =>
      _ServiceRequestDetailPageState();
}

class _ServiceRequestDetailPageState extends State<ServiceRequestDetailPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Datos de muestra para cotizaciones
  late List<Map<String, dynamic>> quotations;

  // Datos de muestra para técnico asignado
  Map<String, dynamic>? assignedTechnician;

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

    _initializeSampleData();
  }

  void _initializeSampleData() {
    // Inicializar cotizaciones de muestra
    quotations = [
      {
        'id': '1',
        'tecnico_nombre': 'Carlos Martínez',
        'especialidad': 'Carpintería',
        'monto': 150000,
        'descripcion': 'Trabajo limpio y a tiempo',
        'rating': 4.8,
        'fecha': DateTime.now().subtract(const Duration(days: 3)),
        'estado': 'aceptada',
      },
      {
        'id': '2',
        'tecnico_nombre': 'Diana López',
        'especialidad': 'Electricidad',
        'monto': 120000,
        'descripcion': 'Experiencia garantizada',
        'rating': 4.5,
        'fecha': DateTime.now().subtract(const Duration(days: 2)),
        'estado': 'pendiente',
      },
    ];

    // Asignar técnico si la solicitud está asignada
    if (widget.request['estado'] == 'asignado') {
      assignedTechnician = {
        'id': '1',
        'nombre': 'Carlos Martínez',
        'especialidad': 'Carpintería',
        'foto_url': 'https://via.placeholder.com/150/555879/FFFFFF?text=Carlos',
        'teléfono': '+57 300 1234567',
        'email': 'carlos.martinez@example.com',
        'rating': 4.8,
        'votos': 156,
        'experiencia_anos': 8,
      };
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
      case 'solicitud':
        return const Color(0xFFF39C12);
      case 'asignado':
        return const Color(0xFF3498DB);
      case 'completado':
        return const Color(0xFF27AE60);
      case 'cancelado':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  IconData _getStateIcon(String estado) {
    switch (estado) {
      case 'solicitud':
        return Icons.hourglass_bottom;
      case 'asignado':
        return Icons.assignment_ind;
      case 'completado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStateLabel(String estado) {
    switch (estado) {
      case 'solicitud':
        return 'Solicitud';
      case 'asignado':
        return 'Asignado';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      return 'Hace ${(difference.inDays / 7).ceil()}s';
    } else {
      return 'Hace ${(difference.inDays / 30).ceil()}m';
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                _buildProblemSection(),
                const SizedBox(height: 20),
                _buildStatusSection(),
                const SizedBox(height: 20),
                if (assignedTechnician != null) ...[
                  _buildAssignedTechnicianSection(),
                  const SizedBox(height: 20),
                ],
                _buildQuotationsSection(),
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
        'Detalle de Solicitud',
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

  /// Sección de información del problema
  Widget _buildProblemSection() {
    return _buildSectionContainer(
      icon: Icons.description,
      title: 'Información del Problema',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Descripción:', widget.request['descripcion_problema']),
          const SizedBox(height: 16),
          _buildInfoRow('Dirección:', widget.request['direccion']),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latitud',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF98A1BC),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.request['latitud']?.toString() ?? '--',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555879),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Longitud',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF98A1BC),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.request['longitud']?.toString() ?? '--',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555879),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Fecha de Solicitud:',
            _formatDate(widget.request['fecha']),
          ),
        ],
      ),
    );
  }

  /// Sección de estado actual
  Widget _buildStatusSection() {
    final stateColor = _getStateColor(widget.request['estado']);
    final stateIcon = _getStateIcon(widget.request['estado']);
    final stateLabel = _getStateLabel(widget.request['estado']);

    return _buildSectionContainer(
      icon: Icons.info,
      title: 'Estado Actual',
      content: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: stateColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: stateColor, width: 2),
          ),
          child: Column(
            children: [
              Icon(stateIcon, size: 48, color: stateColor),
              const SizedBox(height: 12),
              Text(
                stateLabel,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: stateColor,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sección de técnico asignado
  Widget _buildAssignedTechnicianSection() {
    if (assignedTechnician == null) return const SizedBox.shrink();

    final tech = assignedTechnician!;

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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF555879).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFF555879),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      tech['foto_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 40,
                          color: Color(0xFF555879),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tech['nombre'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555879),
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tech['especialidad'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF98A1BC),
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFDED3C4)),
          const SizedBox(height: 16),
          // Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 20, color: const Color(0xFFF39C12)),
              const SizedBox(width: 6),
              Text(
                '${tech['rating']} (${tech['votos']} votos)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF555879),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Información de contacto
          _buildInfoRow('Teléfono:', tech['teléfono']),
          const SizedBox(height: 12),
          _buildInfoRow('Email:', tech['email']),
          const SizedBox(height: 12),
          _buildInfoRow('Experiencia:', '${tech['experiencia_anos']} años'),
        ],
      ),
    );
  }

  /// Sección de cotizaciones recibidas
  Widget _buildQuotationsSection() {
    return _buildSectionContainer(
      icon: Icons.attach_money,
      title: 'Cotizaciones Recibidas (${quotations.length})',
      content: Column(
        children: [
          if (quotations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 48,
                      color: const Color(0xFF98A1BC).withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay cotizaciones aún',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF555879).withOpacity(0.6),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: List.generate(
                quotations.length,
                (index) => Column(
                  children: [
                    _buildQuotationCard(quotations[index]),
                    if (index < quotations.length - 1) ...[
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          if (quotations.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ServiceQuotationsPage(
                        serviceRequestId: widget.request['id'] ?? '1',
                        serviceDescription:
                            widget.request['descripcion_problema'] ?? '',
                      ),
                    ),
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
                icon: const Icon(Icons.compare_arrows),
                label: const Text(
                  'Ver todas las cotizaciones',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tarjeta de cotización individual
  Widget _buildQuotationCard(Map<String, dynamic> quote) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDED3C4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: Nombre y Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote['tecnico_nombre'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555879),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quote['especialidad'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF98A1BC),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: const Color(0xFFF39C12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        quote['rating'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF555879),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Descripción
          Text(
            quote['descripcion'],
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555879),
              fontFamily: 'Montserrat',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Footer: Monto y Estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${(quote['monto'] as int).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
              ),
              // Estado badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: quote['estado'] == 'aceptada'
                      ? const Color(0xFF27AE60).withOpacity(0.2)
                      : const Color(0xFFF39C12).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: quote['estado'] == 'aceptada'
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFF39C12),
                    width: 1,
                  ),
                ),
                child: Text(
                  quote['estado'] == 'aceptada' ? 'Aceptada' : 'Pendiente',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: quote['estado'] == 'aceptada'
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFF39C12),
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

  /// Fila de información reutilizable
  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF98A1BC),
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF555879),
            fontFamily: 'Montserrat',
            height: 1.4,
          ),
        ),
      ],
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555879),
                    fontFamily: 'Montserrat',
                  ),
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
