import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class ServiceQuotationsPage extends StatefulWidget {
  final String serviceRequestId;
  final String serviceDescription;

  const ServiceQuotationsPage({
    super.key,
    required this.serviceRequestId,
    required this.serviceDescription,
  });

  @override
  State<ServiceQuotationsPage> createState() => _ServiceQuotationsPageState();
}

class _ServiceQuotationsPageState extends State<ServiceQuotationsPage>
    with TickerProviderStateMixin {
  // ========================================================================
  // VARIABLES DE ESTADO
  // ========================================================================

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late List<Map<String, dynamic>> quotations;
  String? acceptedQuotationId;

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

    _loadQuotationsFromDatabase();
  }

  Future<void> _loadQuotationsFromDatabase() async {
    try {
      // Cargar cotizaciones reales desde Supabase
      final quotationsData = await DatabaseService.getQuotesForRequest(
        widget.serviceRequestId,
      );

      setState(() {
        quotations = quotationsData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar cotizaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // En caso de error, usar lista vacía
      setState(() {
        quotations = [];
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
  // MÉTODOS CRUD
  // ========================================================================

  /// Aceptar cotización - crea un servicio
  void _acceptQuotation(Map<String, dynamic> quotation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Aceptar Cotización',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Aceptar la cotización de ${quotation['tecnico_nombre']}?',
              style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EBD3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${quotation['precio'].toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF555879),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quotation['mensaje'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF555879),
                      fontFamily: 'Montserrat',
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                acceptedQuotationId = quotation['id'];
                // Cambiar estado de todas las cotizaciones
                for (var q in quotations) {
                  if (q['id'] == quotation['id']) {
                    q['estado'] = 'aceptada';
                  } else {
                    q['estado'] = 'rechazada';
                  }
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cotización aceptada. Servicio creado.'),
                  backgroundColor: Color(0xFF27AE60),
                ),
              );
              // TODO: Crear servicio en tabla services con technician_id y service_request_id
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
            ),
            child: const Text(
              'Aceptar',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rechazar cotización
  void _rejectQuotation(Map<String, dynamic> quotation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Rechazar Cotización',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Rechazar la cotización de ${quotation['tecnico_nombre']}?',
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                quotation['estado'] = 'rechazada';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cotización rechazada'),
                  backgroundColor: Color(0xFFE74C3C),
                ),
              );
              // TODO: Actualizar estado en Supabase
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text(
              'Rechazar',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formatear fecha
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return 'Hace unos minutos';
    } else if (difference.inHours == 1) {
      return 'Hace 1 hora';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }

  /// Obtener color del estado
  Color _getStateColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFF39C12);
      case 'aceptada':
        return const Color(0xFF27AE60);
      case 'rechazada':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  /// Obtener etiqueta de estado
  String _getStateLabel(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'aceptada':
        return 'Aceptada';
      case 'rechazada':
        return 'Rechazada';
      default:
        return estado;
    }
  }

  // ========================================================================
  // CONSTRUIR INTERFAZ
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    final pendingQuotations = quotations
        .where((q) => q['estado'] == 'pendiente')
        .toList();
    final otherQuotations = quotations
        .where((q) => q['estado'] != 'pendiente')
        .toList();

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
                if (acceptedQuotationId != null) ...[
                  _buildAcceptedBanner(),
                  const SizedBox(height: 20),
                ],
                if (pendingQuotations.isNotEmpty) ...[
                  _buildQuotationsSection(
                    'Cotizaciones Pendientes',
                    pendingQuotations,
                    Icons.schedule,
                  ),
                  const SizedBox(height: 20),
                ],
                if (pendingQuotations.isEmpty && otherQuotations.isEmpty)
                  _buildEmptyState(),
                if (otherQuotations.isNotEmpty) ...[
                  _buildQuotationsSection(
                    'Historial',
                    otherQuotations,
                    Icons.history,
                  ),
                ],
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
        'Cotizaciones Recibidas',
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

  /// Banner de cotización aceptada
  Widget _buildAcceptedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27AE60), width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cotización aceptada. Tu servicio ha sido creado.',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF27AE60),
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.attach_money,
              size: 80,
              color: const Color(0xFF98A1BC).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay cotizaciones aún',
              style: TextStyle(
                fontSize: 18,
                color: const Color(0xFF555879).withOpacity(0.7),
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los técnicos enviarán sus ofertas pronto',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF98A1BC).withOpacity(0.7),
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sección de cotizaciones
  Widget _buildQuotationsSection(
    String title,
    List<Map<String, dynamic>> items,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF555879), size: 24),
              const SizedBox(width: 10),
              Text(
                '$title (${items.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555879),
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
        Column(
          children: List.generate(
            items.length,
            (index) => Column(
              children: [
                _buildQuotationCard(items[index]),
                if (index < items.length - 1) const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Tarjeta de cotización
  Widget _buildQuotationCard(Map<String, dynamic> quotation) {
    final stateColor = _getStateColor(quotation['estado']);
    final stateLabel = _getStateLabel(quotation['estado']);
    final isPending = quotation['estado'] == 'pendiente';
    final isAccepted = quotation['estado'] == 'aceptada';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccepted ? const Color(0xFF27AE60) : const Color(0xFF98A1BC),
          width: isAccepted ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF555879).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezado: Avatar, nombre, estado
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF555879).withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFF555879),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          quotation['foto_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: Color(0xFF555879),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nombre, especialidad, rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quotation['tecnico_nombre'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF555879),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            quotation['especialidad'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF98A1BC),
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: const Color(0xFFF39C12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${quotation['rating']} (${quotation['votos']})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF555879),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: stateColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: stateColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  stateLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: stateColor,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Separador
          Container(height: 1, color: const Color(0xFFDED3C4)),
          // Precio y mensaje
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Precio destacado
                Text(
                  '\$${quotation['precio'].toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF555879),
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 12),
                // Mensaje
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EBD3).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    quotation['mensaje'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555879),
                      fontFamily: 'Montserrat',
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Info adicional
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Experiencia',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF98A1BC).withOpacity(0.8),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${quotation['experiencia_anos']} años',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555879),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ofertado',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF98A1BC).withOpacity(0.8),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(quotation['created_at']),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
          ),
          // Botones de acción (solo si está pendiente)
          if (isPending) ...[
            Container(height: 1, color: const Color(0xFFDED3C4)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectQuotation(quotation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE74C3C),
                        side: const BorderSide(
                          color: Color(0xFFE74C3C),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text(
                        'Rechazar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptQuotation(quotation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(
                        'Aceptar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Badge aceptada
          if (isAccepted) ...[
            Container(height: 1, color: const Color(0xFFDED3C4)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF27AE60),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF27AE60),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Cotización Aceptada',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27AE60),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
